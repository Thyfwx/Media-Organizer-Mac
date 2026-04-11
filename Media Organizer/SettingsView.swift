//
//  SettingsView.swift
//  Media Organizer
//

import SwiftUI
import AppKit

struct MediaOrganizerSettingsView: View {
    @AppStorage("aiMode") private var aiMode: Int = 0 
    @AppStorage("namingTemplate") private var namingTemplate: String = "Descriptive Name"
    @AppStorage("customInstructions") private var customInstructions: String = ""
    
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
                .tabItem { Label("General", systemImage: "gearshape") }
            engineTab
                .tabItem { Label("AI Engine", systemImage: "cpu") }
            updatesTab
                .tabItem { Label("Updates", systemImage: "arrow.triangle.2.circlepath") }
        }
        .frame(width: 550, height: 480)
        .padding()
    }
    
    var generalTab: some View {
        Form {
            Section(header: Text("Naming Rules").font(.headline).padding(.bottom, 4)) {
                Picker("Format Template:", selection: $namingTemplate) {
                    Text("Descriptive Name (Default)").tag("Descriptive Name")
                    Text("Date - Name (e.g., 2026-04-10 - Receipt)").tag("YYYY-MM-DD - Descriptive Name")
                    Text("Name (Year) (e.g., Receipt (2026))").tag("Descriptive Name (YYYY)")
                }
                .pickerStyle(.menu)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Custom AI Instructions (Optional):")
                    TextEditor(text: $customInstructions)
                        .frame(height: 80)
                        .font(.body)
                        .padding(4)
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                    Text("e.g. 'Translate to Spanish' or 'Always prefix with Work -'")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
            
            Divider().padding(.vertical, 12)
            
            Section(header: Text("Organization Preferences").font(.headline).padding(.bottom, 4)) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Auto-Sort into Subfolders", isOn: $createSubfolders)
                    Text("The AI will create folders (like 'Receipts' or 'Audio') and move files inside.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 18)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Apply Native macOS Finder Tags", isOn: $applyFinderTags)
                    Text("The AI will color-code and tag files in Finder for easy searching.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 18)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
    }
    
    var engineTab: some View {
        Form {
            Section(header: Text("Processing Engine").font(.headline).padding(.bottom, 4)) {
                Picker("", selection: $aiMode) {
                    Text("✨ Apple Intelligence (On-Device)").tag(0)
                    Text("Local Ollama").tag(1)
                    Text("ChatGPT / Cloud API").tag(2)
                }
                .pickerStyle(.radioGroup)
            }
            
            Divider().padding(.vertical, 12)
            
            if aiMode == 0 {
                VStack(alignment: .center, spacing: 16) {
                    Image(systemName: "apple.intelligence")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Apple Intelligence")
                        .font(.title2).bold()
                    
                    Text("Uses native, on-device intelligence to analyze your files. It is 100% free, fully private, and requires no internet connection or API keys.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.top, 20)
                .frame(maxWidth: .infinity)
            } else if aiMode == 1 {
                Section(header: Text("Local Ollama Configuration").font(.headline).padding(.bottom, 4)) {
                    HStack {
                        Text("Endpoint:")
                        Spacer()
                        Text("http://localhost:11434")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("API Key:")
                        Spacer()
                        Text("Not Required")
                            .foregroundStyle(.secondary)
                    }
                    TextField("Model Name:", text: $localModel)
                        .textFieldStyle(.roundedBorder)
                }
            } else {
                Section(header: Text("Cloud API Configuration").font(.headline).padding(.bottom, 4)) {
                    TextField("API Endpoint:", text: $cloudEndpoint)
                        .textFieldStyle(.roundedBorder)
                    SecureField("API Key (sk-...):", text: $cloudApiKey)
                        .textFieldStyle(.roundedBorder)
                    TextField("Model Name:", text: $cloudModel)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding(20)
    }
    
    var updatesTab: some View {
        VStack(spacing: 24) {
            Image(systemName: "sparkles.rectangle.stack.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            VStack(spacing: 8) {
                Text("Media Organizer")
                    .font(.title).bold()
                Text("Version 1.0 (Alpha)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text("Checking for updates will open the official GitHub repository releases page. If a new version is available, download the latest .dmg and drag it into your Applications folder to update.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            
            Button(action: checkForUpdates) {
                Label("Check for Updates", systemImage: "arrow.down.circle")
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            Spacer()
        }
        .padding(40)
    }
    
    private func checkForUpdates() {
        if let url = URL(string: "https://github.com/Thyfwx/Media-Organizer-Mac/releases") {
            NSWorkspace.shared.open(url)
        }
    }
}
