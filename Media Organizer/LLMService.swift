//
//  LLMService.swift
//  Media Organizer
//

import Foundation

struct LLMConfig {
    var endpoint: URL
    var apiKey: String
    var model: String
    var namingTemplate: String
    var customInstructions: String // NEW
    
    static let localOllama = LLMConfig(
        endpoint: URL(string: "http://localhost:11434/v1/chat/completions")!,
        apiKey: "ollama-local",
        model: "llama3.2",
        namingTemplate: "Descriptive Name",
        customInstructions: ""
    )
}

struct FileMetadata: Codable {
    let proposedName: String
    let category: String
    let artist: String?
    let title: String?
    let album: String?
}

actor LLMService {
    var config: LLMConfig
    
    init(config: LLMConfig = .localOllama) {
        self.config = config
    }
    
    func updateConfig(_ newConfig: LLMConfig) {
        self.config = newConfig
    }
    
    func ensureModelExists() async throws {
        guard config.endpoint.absoluteString.contains("localhost") else { return }
        
        let checkURL = URL(string: "http://localhost:11434/api/tags")!
        let (data, _) = try await URLSession.shared.data(from: checkURL)
        
        let jsonString = String(data: data, encoding: .utf8) ?? ""
        if !jsonString.contains(config.model) {
            let pullURL = URL(string: "http://localhost:11434/api/pull")!
            var request = URLRequest(url: pullURL)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            let payload: [String: Any] = ["name": config.model, "stream": false]
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let sessionConfig = URLSessionConfiguration.default
            sessionConfig.timeoutIntervalForRequest = 600
            sessionConfig.timeoutIntervalForResource = 600
            let longSession = URLSession(configuration: sessionConfig)
            
            let (_, response) = try await longSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw URLError(.badServerResponse)
            }
        }
    }
    
    func analyzeFile(name: String, contentPreview: String?) async throws -> FileMetadata {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let todayDate = formatter.string(from: Date())
        let currentYear = String(Calendar.current.component(.year, from: Date()))
        
        var systemPrompt = """
        You are a highly advanced, expert macOS file organization AI.
        Read the document text or filename and propose a perfect filename and category folder.
        
        CRITICAL RULES:
        1. NO file extensions in the name.
        2. Remove gibberish and messy numbers.
        3. You MUST format the final name to match this template: "\(config.namingTemplate)"
        4. Provide a broad, generic Category Folder Name for this file (e.g., "Receipts", "Taxes", "Images", "Audio", "Work Documents").
        (Note: Today's date is \(todayDate) and the current year is \(currentYear)).
        """
        
        // INJECT CUSTOM USER RULES
        if !config.customInstructions.isEmpty {
            systemPrompt += "\n\nADDITIONAL USER INSTRUCTIONS YOU MUST FOLLOW:\n\(config.customInstructions)"
        }
        
        systemPrompt += """
        
        Respond ONLY with a valid JSON object matching this strict structure:
        {
          "proposedName": "The Final Formatted Name",
          "category": "The Folder Category Name",
          "artist": "Extracted Artist or null",
          "title": "Extracted Title or null",
          "album": "Extracted Album or null"
        }
        """
        
        var userPrompt = "Original Filename: \(name)"
        if let contentPreview, !contentPreview.isEmpty {
            userPrompt += "\n\nExtracted File Data:\n\(contentPreview)"
        }
        
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
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
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
