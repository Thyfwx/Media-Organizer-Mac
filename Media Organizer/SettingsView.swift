//
//  SettingsView.swift
//  Media Organizer
//

import SwiftUI

struct MediaOrganizerSettingsView: View {
    @AppStorage("aiMode") private var aiMode: Int = 0 
    @AppStorage("namingTemplate") private var namingTemplate: String = "Descriptive Name"
    @AppStorage("customInstructions") private var customInstructions: String = "" // NEW: Custom Rules
    
    // Organization Preferences
    @AppStorage("createSubfolders") private var createSubfolders: Bool = true
    @AppStorage("applyFinderTags") private var applyFinderTags: Bool = true
    
    // Cloud Settings
    @AppStorage("cloudEndpoint") private var cloudEndpoint: String = "https://api.openai.com/v1/chat/completions"
    @AppStorage("cloudApiKey") private var cloudApiKey: String = ""
    @AppStorage("cloudModel") private var cloudModel: String = "gpt-4o-mini"
    
    // Local Settings
    @AppStorage("localModel") private var localModel: String = "llama3.2"
    
    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "folder.badge.gearshape") }
            engineTab
                .tabItem { Label("AI Engine", systemImage: "cpu") }
        }
        .frame(width: 500, height: 450)
    }
    
    var generalTab: some View {
        Form {
            Section(header: Text("Naming Rules").bold()) {
                Picker("Format Template:", selection: $namingTemplate) {
                    Text("Descriptive Name (Default)").tag("Descriptive Name")
                    Text("Date - Name (e.g., 2026-04-10 - Receipt)").tag("YYYY-MM-DD - Descriptive Name")
                    Text("Name (Year) (e.g., Receipt (2026))").tag("Descriptive Name (YYYY)")
                }
                
                // NEW: Custom Instructions for the AI
                VStack(alignment: .leading) {
                    Text("Custom AI Instructions (Optional):")
                    TextField("e.g. Translate to Spanish, or always prefix with 'Work -'", text: $customInstructions, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)
                }
                .padding(.top, 4)
            }
            
            Divider().padding(.vertical, 8)
            
            Section(header: Text("Organization Preferences").bold()) {
                Toggle("Auto-Sort into Subfolders", isOn: $createSubfolders)
                Text("If enabled, the AI will create folders (like 'Receipts' or 'Audio') and move the files inside them.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 6)
                
                Toggle("Apply Native macOS Finder Tags", isOn: $applyFinderTags)
                Text("If enabled, the AI will color-code and tag files in Finder so you can search them easily.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(20)
    }
    
    var engineTab: some View {
        Form {
            Picker("Processing Engine:", selection: $aiMode) {
                Text("✨ Apple Intelligence").tag(0)
                Text("Local Ollama").tag(1)
                Text("ChatGPT / Cloud").tag(2)
            }
            .pickerStyle(.radioGroup)
            .padding(.bottom, 10)
            
            Divider().padding(.bottom, 10)
            
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
