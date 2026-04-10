//
//  SettingsView.swift
//  Media Organizer
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("aiMode") private var aiMode: Int = 0 // 0 = Apple Intelligence, 1 = Local, 2 = Cloud
    
    // Cloud Settings
    @AppStorage("cloudEndpoint") private var cloudEndpoint: String = "https://api.openai.com/v1/chat/completions"
    @AppStorage("cloudApiKey") private var cloudApiKey: String = ""
    @AppStorage("cloudModel") private var cloudModel: String = "gpt-4o-mini"
    
    // Local Settings
    @AppStorage("localModel") private var localModel: String = "llama3.2"
    
    var body: some View {
        Form {
            Picker("AI Engine", selection: $aiMode) {
                Text("✨ Apple Intelligence").tag(0)
                Text("Local Ollama").tag(1)
                Text("Advanced Cloud API").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)
            
            if aiMode == 0 {
                // APPLE INTELLIGENCE MODE
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "apple.intelligence")
                            .foregroundStyle(.purple)
                            .font(.title2)
                        Text("Apple Intelligence")
                            .font(.headline)
                    }
                    Text("Apple has not yet released the generative API for third-party apps. Currently using your private Local Engine as a secure fallback.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
                
            } else if aiMode == 1 {
                // LOCAL MODE
                Section(header: Text("Local Settings").bold()) {
                    Text("Endpoint: http://localhost:11434")
                        .foregroundStyle(.secondary)
                    Text("API Key: Not Required")
                        .foregroundStyle(.secondary)
                    TextField("Model Name:", text: $localModel)
                }
                
            } else {
                // CLOUD MODE
                Section(header: Text("Cloud API Settings").bold()) {
                    TextField("API Endpoint:", text: $cloudEndpoint)
                    SecureField("API Key:", text: $cloudApiKey)
                    TextField("Model Name:", text: $cloudModel)
                }
            }
        }
        .padding(20)
        .frame(width: 450)
    }
}
