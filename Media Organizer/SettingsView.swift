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
    
    // Casual Settings
    @AppStorage("enableSounds") private var enableSounds: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("defaultCategory") private var defaultCategory: String = "Organized"
    
    // Cloud Settings
    @AppStorage("cloudProvider") private var cloudProvider: String = "OpenAI"
    @AppStorage("cloudEndpoint") private var cloudEndpoint: String = "https://api.openai.com/v1/chat/completions"
    @AppStorage("cloudApiKey") private var cloudApiKey: String = ""
    @AppStorage("cloudModel") private var cloudModel: String = "gpt-4o-mini"
    
    // Local Settings
    @AppStorage("localModel") private var localModel: String = "llama3.2"
    
    @State private var isCheckingForUpdates = false
    @State private var updateMessage: String? = nil
    @State private var latestVersion: String? = nil
    
    private let currentVersion = "1.0.1" // Alpha 1.0.1
    
    var body: some View {
        TabView {
            generalTab
                .tabItem { Label("General", systemImage: "gearshape") }
            engineTab
                .tabItem { Label("AI Engine", systemImage: "cpu") }
            updatesTab
                .tabItem { Label("Updates", systemImage: "arrow.clockwise.circle") }
        }
        .frame(width: 500, height: 520)
        .padding()
    }
    
    var generalTab: some View {
        ScrollView {
            VStack(spacing: 20) {
                GroupBox(label: Label("Personalize", systemImage: "paintbrush")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("File Naming:", selection: $namingTemplate) {
                            Text("Name Only").tag("Descriptive Name")
                            Text("Category - Name").tag("Category - Descriptive Name")
                            Text("Date - Name").tag("YYYY-MM-DD - Descriptive Name")
                            Text("Date - Category - Name").tag("YYYY-MM-DD - Category - Descriptive Name")
                        }
                        .pickerStyle(.menu)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Special AI Instructions:")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            TextEditor(text: $customInstructions)
                                .frame(height: 60)
                                .padding(4)
                                .background(Color(NSColor.textBackgroundColor))
                                .cornerRadius(6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color(NSColor.separatorColor), lineWidth: 1))
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                GroupBox(label: Label("Organization Style", systemImage: "arrow.left.arrow.right")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Final Destination:", selection: $createSubfolders) {
                            Text("In-Place (Rename only in current folder)").tag(false)
                            Text("Subfolders (Create and sort by category)").tag(true)
                        }
                        .pickerStyle(.radioGroup)

                        Text(createSubfolders ? "Files will be moved into folders like 'Finance' or 'Media' inside their current location." : "Files will stay exactly where they are, just with new descriptive names.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.leading, 20)
                    }
                    .padding(.vertical, 8)
                }

                GroupBox(label: Label("Preferences", systemImage: "hand.tap")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Play sounds when finished", isOn: $enableSounds)
                        Toggle("Send desktop notifications", isOn: $enableNotifications)
                        Toggle("Tag files for Spotlight search", isOn: $applyFinderTags)
                        
                        HStack {
                            Text("Default Folder:")
                            TextField("e.g. Sorted", text: $defaultCategory)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
        }
    }
    
    var engineTab: some View {
        VStack(spacing: 20) {
            Picker("Strategy", selection: $aiMode) {
                Text("Native").tag(0)
                Text("Ollama").tag(1)
                Text("Cloud").tag(2)
            }
            .pickerStyle(.segmented)
            
            if aiMode == 0 {
                VStack(spacing: 12) {
                    Image(systemName: "apple.intelligence")
                        .font(.system(size: 40))
                        .foregroundStyle(.purple.gradient)
                    Text("Apple Intelligence Mode")
                        .font(.headline)
                    Text("Privacy first. Uses our custom on-device engine. Fast, free, and works offline.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else if aiMode == 1 {
                Form {
                    Section("Ollama Settings") {
                        TextField("Model Name:", text: $localModel)
                        LabeledContent("Connection:", value: "Local (http://localhost:11434)")
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 15) {
                    Picker("Provider:", selection: $cloudProvider) {
                        Text("OpenAI (GPT-4o)").tag("OpenAI")
                        Text("Anthropic (Claude)").tag("Anthropic")
                        Text("Groq (Llama 3)").tag("Groq")
                        Text("Custom / Self-Hosted").tag("Custom")
                    }
                    .pickerStyle(.menu)
                    .onChange(of: cloudProvider) { newValue in
                        updateCloudPresets(for: newValue)
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("API Credentials")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Endpoint URL")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("https://...", text: $cloudEndpoint)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("API Key")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            SecureField("Enter your key here", text: $cloudApiKey)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Model Identifier")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            TextField("e.g. gpt-4o", text: $cloudModel)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    .padding(.horizontal, 5)
                }
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func updateCloudPresets(for provider: String) {
        switch provider {
        case "OpenAI":
            cloudEndpoint = "https://api.openai.com/v1/chat/completions"
            cloudModel = "gpt-4o-mini"
        case "Anthropic":
            cloudEndpoint = "https://api.anthropic.com/v1/messages"
            cloudModel = "claude-3-5-sonnet-latest"
        case "Groq":
            cloudEndpoint = "https://api.groq.com/openai/v1/chat/completions"
            cloudModel = "llama-3.1-70b-versatile"
        default:
            break
        }
    }
    
    @State private var isDownloading = false
    @State private var downloadProgress: Double = 0
    @State private var downloadURL: URL? = nil
    
    var updatesTab: some View {
        VStack(spacing: 25) {
            Spacer()
            
            if let icon = NSApp.applicationIconImage {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(radius: 5)
            }
            
            VStack(spacing: 5) {
                Text("Media Organizer")
                    .font(.title2).bold()
                Text("Version \(currentVersion)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.1))
                    .cornerRadius(4)
            }
            
            if let message = updateMessage {
                VStack(spacing: 10) {
                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(latestVersion != nil ? .green : .secondary)
                        .multilineTextAlignment(.center)
                    
                    if isDownloading {
                        VStack(spacing: 4) {
                            ProgressView(value: downloadProgress)
                                .progressViewStyle(.linear)
                                .frame(width: 200)
                            Text("\(Int(downloadProgress * 100))%")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            
            if let version = latestVersion {
                Button(action: { downloadAndInstall(version: version) }) {
                    if isDownloading {
                        Text("Downloading...")
                    } else {
                        Label("Download & Update", systemImage: "arrow.down.circle.fill")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isDownloading)
            } else {
                Button(action: checkForUpdates) {
                    if isCheckingForUpdates {
                        ProgressView().controlSize(.small)
                    } else {
                        Text("Check for Updates")
                    }
                }
                .buttonStyle(.bordered)
                .disabled(isCheckingForUpdates)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func downloadAndInstall(version: String) {
        isDownloading = true
        downloadProgress = 0
        
        let url = URL(string: "https://github.com/Thyfwx/Media-Organizer-Mac/releases/download/v\(version)-alpha/Media-Organizer-Alpha-1.0.dmg")!
        
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent("Media-Organizer-Update.dmg")
        try? FileManager.default.removeItem(at: destination)
        
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
        let task = session.downloadTask(with: url) { localURL, response, error in
            isDownloading = false
            guard let localURL = localURL else {
                updateMessage = "Download failed."
                return
            }
            
            do {
                try FileManager.default.moveItem(at: localURL, to: destination)
                NSWorkspace.shared.open(destination)
                updateMessage = "Update downloaded! Please drag the new version into Applications."
            } catch {
                updateMessage = "Save failed: \(error.localizedDescription)"
            }
        }
        
        // Progress tracking hack for simple URLSession
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
            if !isDownloading { timer.invalidate(); return }
            if downloadProgress < 0.9 {
                withAnimation { downloadProgress += 0.1 }
            }
        }
        
        task.resume()
    }
    
    private func checkForUpdates() {
        isCheckingForUpdates = true
        updateMessage = "Connecting to GitHub..."
        
        guard let url = URL(string: "https://api.github.com/repos/Thyfwx/Media-Organizer-Mac/releases/latest") else {
            isCheckingForUpdates = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isCheckingForUpdates = false
                
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let tagName = json["tag_name"] as? String {
                    
                    let version = tagName.replacingOccurrences(of: "v", with: "").replacingOccurrences(of: "-alpha", with: "")
                    
                    if version > currentVersion {
                        latestVersion = version
                        updateMessage = "A new version (v\(version)) is available!"
                    } else {
                        updateMessage = "You are up to date!"
                    }
                } else {
                    updateMessage = "Could not check for updates. Please try again later."
                }
            }
        }.resume()
    }
}
