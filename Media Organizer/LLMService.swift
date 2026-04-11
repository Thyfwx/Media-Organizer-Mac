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
        // Only the on-device Apple Intelligence mode needs to download the embedded model
        if config.engineType == .appleIntelligence {
            try await EmbeddedAIEngine.shared.loadModel()
        }
    }
    
    func analyzeFile(name: String, contentPreview: String?) async throws -> FileMetadata {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayDate = formatter.string(from: Date())
        let currentYear = String(Calendar.current.component(.year, from: Date()))
        
        var systemPrompt = """
        You are an elite macOS File Systems Expert AI. Your goal is to transform messy filenames into professional, organized assets.
        
        TARGET FORMAT: "\(config.namingTemplate)"
        
        CRITICAL REFINEMENT RULES:
        1. STRIP all file extensions (no .mp4, .pdf, etc).
        2. CLEAN UP: Remove underscores, hyphens, and version strings (v1, final, copy).
        3. BE DESCRIPTIVE: If the content preview is available, use it to create a high-quality name. 
        4. CATEGORIZATION: Assign a single, broad category folder name (e.g., 'Finance', 'Media', 'Projects', 'Legal').
        5. MEDIA METADATA: If the file is a song or video, attempt to extract 'artist', 'title', and 'album' from the context.
        
        TODAY'S CONTEXT:
        - Date: \(todayDate)
        - Year: \(currentYear)
        
        OUTPUT FORMAT: You MUST return a valid JSON object only.
        """
        
        if !config.customInstructions.isEmpty {
            systemPrompt += "\n\nSTRICT USER OVERRIDES:\n\(config.customInstructions)"
        }
        
        var userPrompt = "FILE TO ORGANIZE:\n- Raw Filename: \(name)"
        if let contentPreview, !contentPreview.isEmpty {
            userPrompt += "\n- Content Snippet: \(contentPreview)"
        }
        
        // ROUTE 1: Use the Embedded Native Engine! (Apple Intelligence Mode)
        if config.engineType == .appleIntelligence {
            let rawJSON = try await EmbeddedAIEngine.shared.generateResponse(systemPrompt: systemPrompt, userPrompt: userPrompt)
            return try decodeMetadata(fromJSON: rawJSON)
        }
        
        // ROUTE 2: Use Network API (Ollama or Cloud)
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
    // These helpers are nonisolated to satisfy the Swift 6 compiler's actor isolation rules.
    
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
