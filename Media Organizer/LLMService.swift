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
        You are a highly advanced macOS file organization AI.
        Read the document text or filename and propose a perfect filename and category folder.
        
        CRITICAL RULES:
        1. NO file extensions in the name.
        2. Remove gibberish.
        3. You MUST format the final name to match this template: "\(config.namingTemplate)"
        4. Provide a broad Category Folder Name (e.g., "Receipts", "Images").
        (Note: Today's date is \(todayDate) and the current year is \(currentYear)).
        """
        
        if !config.customInstructions.isEmpty {
            systemPrompt += "\n\nADDITIONAL USER INSTRUCTIONS YOU MUST FOLLOW:\n\(config.customInstructions)"
        }
        
        var userPrompt = "Original Filename: \(name)"
        if let contentPreview, !contentPreview.isEmpty {
            userPrompt += "\n\nExtracted File Text:\n\(contentPreview)"
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
