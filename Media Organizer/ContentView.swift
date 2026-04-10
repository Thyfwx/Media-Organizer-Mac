//
//  ContentView.swift
//  Media Organizer
//
//  Created by Xavier Scott on 4/10/26.
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit
import PDFKit
import Vision

struct ContentView: View {
    @State private var isDropTargeted = false
    @State private var queuedFiles: [URL] = []
    
    // Sandbox Security Keys
    @State private var securedURLs: [URL] = []
    @State private var securedFolders: [URL] = []
    
    // Processing State
    @State private var isProcessing = false
    @State private var isDownloadingModel = false
    @State private var shouldStop = false
    @State private var processedFilesCount = 0
    @State private var totalFiles = 0
    @State private var statusMessage = ""
    @State private var lastError: String? = nil
    
    // Animation State
    @State private var rotationAngle: Double = 0
    @State private var gradientAnimation = false
    
    // Settings
    @AppStorage("aiMode") private var aiMode: Int = 0
    @AppStorage("namingTemplate") private var namingTemplate: String = "Descriptive Name"
    @AppStorage("cloudEndpoint") private var cloudEndpoint: String = "https://api.openai.com/v1/chat/completions"
    @AppStorage("cloudApiKey") private var cloudApiKey: String = ""
    @AppStorage("cloudModel") private var cloudModel: String = "gpt-4o-mini"
    @AppStorage("localModel") private var localModel: String = "llama3.2"
    
    var body: some View {
        // THE MAIN CONTENT
        VStack(spacing: 20) {
            Spacer()
            
            ZStack {
                Circle()
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 4)
                    .frame(width: 90, height: 90)
                
                if isProcessing || isDownloadingModel {
                    Circle()
                        .trim(from: 0, to: 0.75)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 90, height: 90)
                        .rotationEffect(.degrees(rotationAngle))
                        .onAppear {
                            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                                rotationAngle = 360
                            }
                        }
                }
                
                Image(systemName: isDownloadingModel ? "icloud.and.arrow.down.fill" : (isProcessing ? "sparkles" : "tray.and.arrow.down.fill"))
                    .resizable()
                    .scaledToFit()
                    .frame(width: 36, height: 36)
                    .foregroundStyle(isDropTargeted || isProcessing || isDownloadingModel ? Color.accentColor : Color.primary.opacity(0.7))
            }
            .padding(.bottom, 8)
            
            if isDownloadingModel {
                Text("Preparing Intelligence...")
                    .font(.title3.weight(.medium))
            } else if isProcessing {
                Text("Organizing Files...")
                    .font(.title3.weight(.medium))
            } else if queuedFiles.isEmpty {
                Text(isDropTargeted ? "Drop to Queue" : "Drag & Drop Files Here")
                    .font(.title3.weight(.medium))
            } else {
                Text("\(queuedFiles.count) File(s) Ready")
                    .font(.title3.weight(.medium))
            }
            
            if isProcessing || isDownloadingModel {
                VStack(spacing: 12) {
                    ProgressView(value: Double(processedFilesCount), total: Double(totalFiles))
                        .progressViewStyle(.linear)
                        .frame(width: 220)
                        .tint(.accentColor)
                    
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Button(role: .destructive, action: { shouldStop = true }) {
                        Text("Stop Processing")
                            .font(.callout.weight(.medium))
                    }
                    .buttonStyle(.borderless)
                    .padding(.top, 4)
                }
            } else if !queuedFiles.isEmpty {
                HStack(spacing: 16) {
                    Button(role: .cancel, action: resetQueue) {
                        Text("Clear")
                            .frame(width: 80)
                    }
                    .controlSize(.large)
                    
                    Button(action: { Task { await processQueue() } }) {
                        Text("Start Organizing")
                            .bold()
                            .frame(width: 130)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.accentColor)
                }
                .padding(.top, 4)
            }
            
            if let lastError {
                Text(lastError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
            }
            
            Spacer()
            
            Text("Alpha 1.0 • By Xavier Scott")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary.opacity(0.6))
                .padding(.bottom, 10)
        }
        .padding(.top, 40)
        .padding(.horizontal, 30)
        // This makes the window resizable, but it won't shrink smaller than 400x420
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 420, maxHeight: .infinity)
        // THE LIQUID GLASS BACKGROUND - Now natively bound to the background!
        .background {
            ZStack {
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.5), Color.purple.opacity(0.5), Color.cyan.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .hueRotation(.degrees(gradientAnimation ? 360 : 0))
                .animation(.linear(duration: 8.0).repeatForever(autoreverses: false), value: gradientAnimation)
                .onAppear { gradientAnimation = true }
                
                Rectangle().fill(.ultraThinMaterial)
            }
            .ignoresSafeArea(.all) // Perfectly fills the window, destroying the white bar
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if #available(macOS 14.0, *) {
                    SettingsLink { Label("Settings", systemImage: "gearshape.fill") }
                        .help("Open AI Settings")
                } else {
                    Button(action: { NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .help("Open AI Settings")
                }
            }
        }
        .dropDestination(for: URL.self) { items, location in
            lastError = nil
            var gatheredURLs: [URL] = []
            
            for url in items {
                if url.startAccessingSecurityScopedResource() { securedURLs.append(url) }
                var isDirectory: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                    if isDirectory.boolValue {
                        if let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
                            for case let fileURL as URL in enumerator {
                                if let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey]),
                                   let isDir = resourceValues.isDirectory, !isDir {
                                    gatheredURLs.append(fileURL)
                                }
                            }
                        }
                    } else {
                        gatheredURLs.append(url)
                    }
                }
            }
            guard !gatheredURLs.isEmpty else { return false }
            
            withAnimation {
                queuedFiles.append(contentsOf: gatheredURLs)
                totalFiles = queuedFiles.count
            }
            return true
        } isTargeted: { targeted in
            withAnimation(.snappy) { isDropTargeted = targeted }
        }
    }
    
    @MainActor
    private func requestFolderAccess(for folderURL: URL) async -> URL? {
        return await withCheckedContinuation { continuation in
            let panel = NSOpenPanel()
            panel.message = "macOS Sandbox requires permission to rename files inside this folder."
            panel.prompt = "Grant Access"
            panel.directoryURL = folderURL
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.canCreateDirectories = false
            panel.allowsMultipleSelection = false
            
            if panel.runModal() == .OK, let selectedURL = panel.url {
                if selectedURL.startAccessingSecurityScopedResource() {
                    continuation.resume(returning: selectedURL)
                } else {
                    continuation.resume(returning: nil)
                }
            } else {
                continuation.resume(returning: nil)
            }
        }
    }
    
    private func extractContentPreview(from file: URL) -> String? {
        let ext = file.pathExtension.lowercased()
        if ext == "pdf" {
            guard let pdf = PDFDocument(url: file), let page = pdf.page(at: 0), let text = page.string else { return nil }
            return String(text.prefix(1500))
        } else if ["txt", "md", "csv", "json"].contains(ext) {
            guard let text = try? String(contentsOf: file) else { return nil }
            return String(text.prefix(1500))
        } else if ["png", "jpg", "jpeg", "heic", "tiff"].contains(ext) {
            guard let imageSource = CGImageSourceCreateWithURL(file as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else { return nil }
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            try? requestHandler.perform([request])
            let recognizedText = request.results?.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
            if let text = recognizedText, !text.isEmpty { return String(text.prefix(1500)) }
        }
        return nil
    }
    
    private func processQueue() async {
        isProcessing = true
        shouldStop = false
        
        let config: LLMConfig
        if aiMode == 0 || aiMode == 1 {
            config = LLMConfig(endpoint: URL(string: "http://localhost:11434/v1/chat/completions")!, apiKey: "local", model: localModel, namingTemplate: namingTemplate)
        } else {
            config = LLMConfig(endpoint: URL(string: cloudEndpoint) ?? URL(string: "https://api.openai.com/v1/chat/completions")!, apiKey: cloudApiKey, model: cloudModel, namingTemplate: namingTemplate)
        }
        
        let llm = LLMService(config: config)
        let fileProcessor = FileProcessor()
        
        if aiMode == 0 || aiMode == 1 {
            do {
                isDownloadingModel = true
                try await llm.ensureModelExists()
                withAnimation { isDownloadingModel = false }
            } catch {
                withAnimation { isDownloadingModel = false }
                lastError = "Could not start On-Device Intelligence."
                isProcessing = false
                return
            }
        }
        
        while !queuedFiles.isEmpty {
            if shouldStop {
                lastError = "Processing Cancelled."
                break
            }
            
            let file = queuedFiles.removeFirst()
            statusMessage = "Analyzing: \(file.lastPathComponent)"
            
            if aiMode == 2 && cloudApiKey.isEmpty {
                lastError = "Please enter an API Key in Settings."
                break
            }
            
            do {
                let preview = extractContentPreview(from: file)
                let metadata = try await llm.analyzeFile(name: file.deletingPathExtension().lastPathComponent, contentPreview: preview)
                
                statusMessage = "Renaming to: \(metadata.proposedName)"
                try await fileProcessor.process(file: file, with: metadata)
                processedFilesCount += 1
                
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && nsError.code == 513 {
                    let folderURL = file.deletingLastPathComponent()
                    if let securedFolder = await requestFolderAccess(for: folderURL) {
                        securedFolders.append(securedFolder)
                        do {
                            let preview = extractContentPreview(from: file)
                            let metadata = try await llm.analyzeFile(name: file.deletingPathExtension().lastPathComponent, contentPreview: preview)
                            try await fileProcessor.process(file: file, with: metadata)
                            processedFilesCount += 1
                        } catch {
                            lastError = "Failed to save even with permission."
                        }
                    } else {
                        lastError = "Permission to the folder was denied."
                        queuedFiles.insert(file, at: 0)
                        break
                    }
                } else {
                    lastError = "Error with \(file.lastPathComponent): \(error.localizedDescription)"
                }
            }
        }
        
        if !shouldStop && queuedFiles.isEmpty {
            statusMessage = "Done!"
            NSSound(named: "Glass")?.play()
            try? await Task.sleep(for: .seconds(2))
            resetQueue()
        } else {
            isProcessing = false
            statusMessage = ""
        }
    }
    
    private func resetQueue() {
        for url in securedURLs { url.stopAccessingSecurityScopedResource() }
        for folder in securedFolders { folder.stopAccessingSecurityScopedResource() }
        securedURLs.removeAll()
        securedFolders.removeAll()
        
        withAnimation {
            totalFiles = 0
            processedFilesCount = 0
            statusMessage = ""
            isProcessing = false
            isDownloadingModel = false
            shouldStop = false
            rotationAngle = 0
            queuedFiles.removeAll()
        }
    }
}

#Preview {
    ContentView()
}
