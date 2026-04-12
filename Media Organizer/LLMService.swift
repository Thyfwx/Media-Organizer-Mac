//
//  LLMService.swift
//  Media Organizer
//

import Foundation

// MARK: - THE MAIN AI ROUTER
actor LLMService {
    var config: LLMConfig
    
    init(config: LLMConfig) {
        self.config = config
    }
    
    func ensureModelExists() async throws {
        // Only the Pro Local AI mode needs to download the heavy LLM model
        if config.engineType == .proLocalAI {
            try await EmbeddedAIEngine.shared.loadModel()
        }
    }
    
    func analyzeFile(name: String, contentPreview: String?) async throws -> FileMetadata {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayDate = formatter.string(from: Date())
        let currentYear = String(Calendar.current.component(.year, from: Date()))
        
        var systemPrompt = """
        You are an Elite Forensic File Analyst and Naming Rehab Specialist. 
        Your mission is to perform a 'Deep Reconstruction' of messy filenames.
        
        GOAL: Total clarity. A user must know the Subject, Date, and Source of a file instantly.
        
        FORENSIC ANALYSIS RULES:
        1. DATA MINING: Scan the 'Content Snippet' for specific identifiers:
           - Financial: Total amounts, invoice numbers, vendor names (Amazon, Apple, etc).
           - Professional: Project names, client names, meeting dates.
           - Personal: Specific names, locations mentioned, event titles.
        2. CLEANING: Aggressively strip underscores, hyphens, and 'jibber-jabber' (v1, final, copy, scan_001).
        3. NAMING: Construct a premium name. Example: 'Apple Store Receipt - iPhone 15 Pro - 2026-04-11'.
        4. CATEGORIZATION: Use specific, logical folders (e.g., 'Taxes 2026', 'Work Contracts', 'Family Photos').
        
        TARGET FORMAT: "\(config.namingTemplate)"
        (Context: Today is \(todayDate)).
        
        OUTPUT: Return valid JSON with 'proposedName' and 'category'.
        """
        
        if !config.customInstructions.isEmpty {
            systemPrompt += "\n\nSTRICT USER OVERRIDES:\n\(config.customInstructions)"
        }
        
        var userPrompt = "FILE TO ORGANIZE:\n- Raw Filename: \(name)"
        if let contentPreview, !contentPreview.isEmpty {
            userPrompt += "\n- Content Snippet: \(contentPreview)"
        }
        
        // ROUTE 1 & 2: Use the Embedded Engines
        if config.engineType == .coreAI || config.engineType == .proLocalAI {
            let rawJSON = try await EmbeddedAIEngine.shared.generateResponse(systemPrompt: systemPrompt, userPrompt: userPrompt)
            return try decodeMetadata(fromJSON: rawJSON)
        }
        
        // ROUTE 3: Use Network API (Ollama or Cloud)
        let payload: [String: Any] = [
            "model": config.model,
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ]
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: payload)
        var request = URLRequest(url: config.endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Only add Authorization if it's not a local Ollama call
        if config.engineType == .cloudAPI && !config.apiKey.isEmpty {
            request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try decodeMetadata(fromData: data)
    }
    
    // MARK: - NON-ISOLATED HELPERS
    private nonisolated func decodeMetadata(fromJSON json: String) throws -> FileMetadata {
        guard let data = json.data(using: .utf8) else { throw URLError(.cannotParseResponse) }
        return try JSONDecoder().decode(FileMetadata.self, from: data)
    }
    
    private nonisolated func decodeMetadata(fromData data: Data) throws -> FileMetadata {
        struct ChatResponse: Decodable {
            struct Choice: Decodable {
                struct Message: Decodable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let decodedResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let contentString = decodedResponse.choices.first?.message.content,
              let contentData = contentString.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        return try JSONDecoder().decode(FileMetadata.self, from: contentData)
    }
}
