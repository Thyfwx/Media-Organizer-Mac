//
//  SettingsView.swift
//  Media Organizer
//

import SwiftUI

struct MediaOrganizerSettingsView: View {
    @AppStorage("aiMode") private var aiMode: Int = 0 // 0 = Apple Intelligence, 1 = Local, 2 = Custom Cloud
    
    // NEW: Custom Naming Templates
    @AppStorage("namingTemplate") private var namingTemplate: String = "Descriptive Name"
    
    // Cloud Settings
    @AppStorage("cloudEndpoint") private var cloudEndpoint: String = "https://api.openai.com/v1/chat/completions"
    @AppStorage("cloudApiKey") private var cloudApiKey: String = ""
    @AppStorage("cloudModel") private var cloudModel: String = "gpt-4o-mini"
    
    // Local Settings
    @AppStorage("localModel") private var localModel: String = "llama3.2"
    
    var body: some View {
        TabView {
            engineTab
                .tabItem {
                    Label("AI Engine", systemImage: "cpu")
                }
        }
        .frame(width: 480, height: 420) // Made slightly taller to fit the new templates
    }
    
    var engineTab: some View {
        Form {
            // NEW: Naming Templates UI
            Section(header: Text("Naming Rules").bold()) {
                Picker("Format Template:", selection: $namingTemplate) {
                    Text("Descriptive Name (Default)").tag("Descriptive Name")
                    Text("Date - Name (e.g., 2026-04-10 - Receipt)").tag("YYYY-MM-DD - Descriptive Name")
                    Text("Name (Year) (e.g., Receipt (2026))").tag("Descriptive Name (YYYY)")
                }
                Text("The AI will automatically format your files to match this template.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }
            
            Divider().padding(.bottom, 8)
            
            Picker("Processing Engine:", selection: $aiMode) {
                Text("✨ Apple Intelligence").tag(0)
                Text("Local Ollama").tag(1)
                Text("ChatGPT / Cloud").tag(2)
            }
            .pickerStyle(.radioGroup)
            .padding(.bottom, 10)
            
            if aiMode == 0 {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "apple.intelligence")
                            .foregroundStyle(.purple)
                            .font(.largeTitle)
                        Text("Apple Intelligence")
                            .font(.title2).bold()
                    }
                    Text("Uses native, on-device intelligence to analyze your files. It is 100% free, fully private, and requires no internet connection or API keys.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            } else if aiMode == 1 {
                Section(header: Text("Local Ollama Settings").bold()) {
                    Text("Endpoint: http://localhost:11434")
                        .foregroundStyle(.secondary)
                    Text("API Key: Not Required")
                        .foregroundStyle(.secondary)
                    TextField("Model Name:", text: $localModel)
                }
            } else {
                Section(header: Text("ChatGPT / Cloud Settings").bold()) {
                    TextField("API Endpoint:", text: $cloudEndpoint)
                    SecureField("API Key (sk-...):", text: $cloudApiKey)
                    TextField("Model Name:", text: $cloudModel)
                }
            }
        }
        .padding(20)
    }
}
