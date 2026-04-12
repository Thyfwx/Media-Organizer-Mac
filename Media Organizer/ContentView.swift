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
import AVFoundation 
@preconcurrency import UserNotifications
import QuickLookThumbnailing

struct ContentView: View {
    @State private var isDropTargeted = false
    @State private var queuedFiles: [URL] = []
    @State private var proposedChanges: [ProposedChange] = []
    @State private var processedHistory: [ProcessedFileRecord] = []
    
    @State private var isProcessing = false
    @State private var isReviewing = false
    @State private var totalFiles = 0
    @State private var processedFilesCount = 0
    @State private var statusMessage = ""
    @State private var lastError: String? = nil
    @State private var showHistory = false
    @State private var isDownloadingModel = false
    @State private var shouldStop = false
    @State private var gradientAnimation = false
    @State private var rotationAngle: Double = 0
    
    @State private var securedURLs: [URL] = []
    @State private var securedFolders: [URL] = []
    
    @AppStorage("aiMode") private var aiMode: Int = 0
    @AppStorage("namingTemplate") private var namingTemplate: String = "Descriptive Name"
    @AppStorage("customInstructions") private var customInstructions: String = ""
    @AppStorage("cloudEndpoint") private var cloudEndpoint: String = "https://api.openai.com/v1/chat/completions"
    @AppStorage("cloudApiKey") private var cloudApiKey: String = ""
    @AppStorage("cloudModel") private var cloudModel: String = "gpt-4o-mini"
    @AppStorage("localModel") private var localModel: String = "llama3.2"
    @AppStorage("createSubfolders") private var createSubfolders: Bool = false
    @AppStorage("applyFinderTags") private var applyFinderTags: Bool = true
    
    // Casual Settings
    @AppStorage("enableSounds") private var enableSounds: Bool = true
    @AppStorage("enableNotifications") private var enableNotifications: Bool = true
    @AppStorage("defaultCategory") private var defaultCategory: String = "Organized"
    
    var body: some View {
        ZStack {
            // MARK: - PREMIUM GLASS BACKGROUND
            ZStack {
                VisualEffectView()
                    .ignoresSafeArea()
                
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.77, blue: 0.89).opacity(0.4), // Pastel Pink
                        Color(red: 0.88, green: 0.76, blue: 0.99).opacity(0.4), // Pastel Purple
                        Color(red: 0.63, green: 0.77, blue: 0.99).opacity(0.4), // Pastel Blue
                        Color(red: 0.76, green: 0.98, blue: 0.73).opacity(0.3)  // Pastel Mint
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .hueRotation(.degrees(gradientAnimation ? 45 : 0))
                .animation(.easeInOut(duration: 10.0).repeatForever(autoreverses: true), value: gradientAnimation)
                .onAppear { gradientAnimation = true }
                
                if isDropTargeted {
                    Color.accentColor.opacity(0.15)
                        .transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
            
            if isReviewing {
                reviewScreen
            } else {
                mainScreen
            }
        }
        .frame(minWidth: 400, maxWidth: .infinity, minHeight: 420, maxHeight: .infinity)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showHistory.toggle() }) {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .help("View organized files")
                .disabled(processedHistory.isEmpty)
                .popover(isPresented: $showHistory, arrowEdge: .bottom) {
                    historyPopover
                }
            }
            
            ToolbarItem(placement: .primaryAction) {
                if #available(macOS 14.0, *) {
                    SettingsLink { Label("Settings", systemImage: "gearshape.fill") }
                        .help("Open AI Settings")
                        .disabled(isReviewing || isProcessing)
                } else {
                    Button(action: { NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil) }) {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .help("Open AI Settings")
                    .disabled(isReviewing || isProcessing)
                }
            }
        }
        .dropDestination(for: URL.self) { items, location in
            guard !isReviewing && !isProcessing else { return false }
            
            // Play a cute "Pop" sound when files are dropped!
            if enableSounds { NSSound(named: "Pop")?.play() }
            
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
            if !isReviewing && !isProcessing {
                withAnimation(.snappy) { isDropTargeted = targeted }
            }
        }
    }
    
    // MARK: - COMPONENTS
    
    var mainScreen: some View {
        VStack(spacing: 25) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 140, height: 140)
                
                Image(systemName: isDownloadingModel ? "icloud.and.arrow.down.fill" : (isProcessing ? "sparkles" : "tray.and.arrow.down.fill"))
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor.gradient)
                    .rotationEffect(.degrees(isProcessing ? rotationAngle : 0))
                    .animation(isProcessing ? .linear(duration: 2).repeatForever(autoreverses: false) : .default, value: rotationAngle)
                    .onAppear { if isProcessing { rotationAngle = 360 } }
            }
            
            VStack(spacing: 10) {
                Text(isProcessing ? "Analyzing Media..." : (queuedFiles.isEmpty ? "Drag Media Here" : "\(queuedFiles.count) Files Queued"))
                    .font(.title2).bold()
                
                if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if isProcessing {
                VStack(spacing: 8) {
                    ProgressView(value: Double(processedFilesCount), total: Double(totalFiles))
                        .progressViewStyle(.linear)
                        .frame(width: 250)
                    
                    Text("\(processedFilesCount) of \(totalFiles)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    Button("Stop") { shouldStop = true }
                        .buttonStyle(.link)
                        .foregroundStyle(.red)
                }
            } else if !queuedFiles.isEmpty {
                HStack(spacing: 16) {
                    Button(role: .cancel, action: resetQueue) {
                        Text("Clear")
                            .frame(width: 80)
                    }
                    .controlSize(.large)
                    
                    Button(action: { Task { await analyzeQueue() } }) {
                        Text("Analyze Now")
                            .bold()
                            .frame(width: 120)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            if let error = lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 8).fill(.red.opacity(0.1)))
            }
            
            Spacer()
        }
    }
    
    var reviewScreen: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Review Proposed Changes")
                    .font(.headline)
                Spacer()
                Text("\(proposedChanges.count) items")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            List {
                ForEach(proposedChanges) { change in
                    ReviewRow(change: binding(for: change), onRemove: {
                        let idToRemove = change.id
                        DispatchQueue.main.async {
                            withAnimation {
                                proposedChanges.removeAll(where: { $0.id == idToRemove })
                            }
                        }
                    })
                }
            }
            
            Divider()
            
            HStack {
                Button("Cancel") {
                    withAnimation {
                        isReviewing = false
                        resetQueue()
                    }
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Organize All") {
                    Task { await executeChanges() }
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
    }
    
    private func binding(for change: ProposedChange) -> Binding<ProposedChange> {
        guard let index = proposedChanges.firstIndex(where: { $0.id == change.id }) else {
            fatalError("Change not found")
        }
        return $proposedChanges[index]
    }
    
    var historyPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Descriptive History")
                    .font(.headline)
                Spacer()
                Button("Clear All") { processedHistory.removeAll() }
                    .buttonStyle(.link)
                    .font(.caption)
            }
            .padding([.top, .horizontal])
            
            Divider()
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(processedHistory.reversed()) { record in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: categoryIcon(for: record.category))
                                    .foregroundStyle(Color.accentColor)
                                Text(record.finalURL.lastPathComponent)
                                    .font(.system(size: 13, weight: .bold))
                                    .lineLimit(1)
                                Spacer()
                                Text(record.dateProcessed, style: .date)
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Original: \(record.originalName)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                
                                Text("Category: \(record.category)")
                                    .font(.system(size: 10))
                                    .foregroundStyle(.secondary)
                            }
                            
                            HStack {
                                Spacer()
                                Button(action: { undoMove(for: record) }) {
                                    Label("Undo", systemImage: "arrow.uturn.backward")
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                                
                                Button(action: { NSWorkspace.shared.activateFileViewerSelecting([record.finalURL]) }) {
                                    Label("Find", systemImage: "magnifyingglass")
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(categoryColor(for: record.category).opacity(0.08))
                        )
                    }
                }
                .padding(.horizontal)
            }
            .frame(width: 350, height: 450)
        }
    }
    
    private func categoryColor(for category: String) -> Color {
        switch category.lowercased() {
        case "finance": return .green
        case "legal": return .blue
        case "media": return .purple
        case "images": return .pink
        case "career": return .orange
        case "taxes": return .red
        case "screenshots": return .cyan
        default: return .secondary
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "finance": return "dollarsign.circle.fill"
        case "legal": return "doc.text.fill"
        case "media": return "play.circle.fill"
        case "images": return "photo.fill"
        case "career": return "briefcase.fill"
        case "taxes": return "building.columns.fill"
        case "screenshots": return "macwindow"
        default: return "folder.fill"
        }
    }

    // MARK: - FILE LOGIC
    
    private func generateThumbnail(for url: URL) async -> NSImage? {
        let size = CGSize(width: 88, height: 88)
        let request = QLThumbnailGenerator.Request(fileAt: url, size: size, scale: NSScreen.main?.backingScaleFactor ?? 2.0, representationTypes: .thumbnail)
        
        do {
            let preview = try await QLThumbnailGenerator.shared.generateBestRepresentation(for: request)
            return preview.nsImage
        } catch {
            return nil
        }
    }
    
    private func undoMove(for record: ProcessedFileRecord) {
        do {
            if FileManager.default.fileExists(atPath: record.finalURL.path) {
                var resourceValues = URLResourceValues()
                resourceValues.tagNames = nil
                var tempURL = record.finalURL
                try? tempURL.setResourceValues(resourceValues)
                
                try FileManager.default.moveItem(at: record.finalURL, to: record.originalURL)
                
                withAnimation {
                    if let idx = processedHistory.firstIndex(where: { $0.id == record.id }) {
                        processedHistory.remove(at: idx)
                    }
                }
            }
        } catch {
            lastError = "Undo failed: \(error.localizedDescription)"
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
    
    private func extractContentPreview(from file: URL) async -> String? {
        let ext = file.pathExtension.lowercased()
        
        if ext == "pdf" {
            guard let pdf = PDFDocument(url: file) else { return "Encrypted or Invalid PDF" }
            var fullText = ""
            // Get text from first 5 pages for deeper context
            for i in 0..<min(pdf.pageCount, 5) {
                if let pageText = pdf.page(at: i)?.string {
                    fullText += pageText + " "
                }
            }
            return String(fullText.prefix(3000))
            
        } else if ["txt", "md", "csv", "json"].contains(ext) {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { return nil }
            return String(text.prefix(3000))
            
        } else if ["png", "jpg", "jpeg", "heic", "tiff"].contains(ext) {
            guard let imageSource = CGImageSourceCreateWithURL(file as CFURL, nil) else { return nil }
            
            // Extract EXIF/IPTC Metadata Clues
            var metaClues = ""
            if let dict = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: Any] {
                if let tiff = dict["{TIFF}"] as? [String: Any], let model = tiff["Model"] as? String {
                    metaClues += "Camera: \(model). "
                }
                if let exif = dict["{Exif}"] as? [String: Any], let date = exif["DateTimeOriginal"] as? String {
                    metaClues += "Captured: \(date). "
                }
            }
            
            guard let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else { return nil }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let textRequest = VNRecognizeTextRequest()
            textRequest.recognitionLevel = .accurate
            
            let classifyRequest = VNClassifyImageRequest()
            
            try? requestHandler.perform([textRequest, classifyRequest])
            
            var imageDescription = "IMAGE FORENSICS:\n"
            imageDescription += "- Meta Clues: \(metaClues)\n"
            
            if let text = textRequest.results?.compactMap({ $0.topCandidates(1).first?.string }).joined(separator: " "), !text.isEmpty {
                imageDescription += "- Text in image: \(text)\n"
            }
            if let classifications = classifyRequest.results?.filter({ $0.hasMinimumRecall(0.5, forPrecision: 0.5) }).prefix(8).map({ $0.identifier }).joined(separator: ", ") {
                imageDescription += "- Visual Clues: \(classifications)"
            }
            return String(imageDescription.prefix(3000))
            
        } else if ["mp4", "mov", "m4a", "mp3", "wav"].contains(ext) {
            let asset = AVURLAsset(url: file)
            var mediaInfo = "MEDIA METADATA:\n"
            
            if let duration = try? await asset.load(.duration) {
                mediaInfo += "- Duration: \(Int(CMTimeGetSeconds(duration))) seconds\n"
            }
            
            let formats = try? await asset.load(.availableMetadataFormats)
            for format in formats ?? [] {
                if let metadata = try? await asset.loadMetadata(for: format) {
                    for item in metadata {
                        if let key = item.commonKey?.rawValue {
                            if let val = try? await item.load(.stringValue) {
                                mediaInfo += "- \(key): \(val)\n"
                            }
                        }
                    }
                }
            }
            return String(mediaInfo.prefix(2000))
        }
        return "No specific content available for this file type."
    }
    
    @MainActor
    private func analyzeQueue() async {
        isProcessing = true
        shouldStop = false
        proposedChanges.removeAll()
        totalFiles = queuedFiles.count
        processedFilesCount = 0
        
        let config: LLMConfig
        if aiMode == 0 {
            config = LLMConfig(engineType: .coreAI, endpoint: URL(string: "http://localhost")!, apiKey: "", model: "heuristic", namingTemplate: namingTemplate, customInstructions: customInstructions)
        } else if aiMode == 1 {
            config = LLMConfig(engineType: .proLocalAI, endpoint: URL(string: "http://localhost")!, apiKey: "", model: "embedded", namingTemplate: namingTemplate, customInstructions: customInstructions)
        } else if aiMode == 2 {
            config = LLMConfig(engineType: .localOllama, endpoint: URL(string: "http://localhost:11434/v1/chat/completions")!, apiKey: "local", model: localModel, namingTemplate: namingTemplate, customInstructions: customInstructions)
        } else {
            config = LLMConfig(engineType: .cloudAPI, endpoint: URL(string: cloudEndpoint) ?? URL(string: "https://api.openai.com/v1/chat/completions")!, apiKey: cloudApiKey, model: cloudModel, namingTemplate: namingTemplate, customInstructions: customInstructions)
        }
        
        let llm = LLMService(config: config)
        
        if aiMode == 1 {
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
            if shouldStop { break }
            let file = queuedFiles.removeFirst()
            statusMessage = "Analyzing: \(file.lastPathComponent)"
            
            if aiMode == 3 && cloudApiKey.isEmpty {
                lastError = "Please enter an API Key in Settings."
                break
            }
            
            let thumbnail = await generateThumbnail(for: file)
            
            do {
                let preview = await extractContentPreview(from: file)
                let metadata = try await llm.analyzeFile(name: file.deletingPathExtension().lastPathComponent, contentPreview: preview)
                
                let change = ProposedChange(
                    originalURL: file,
                    proposedName: metadata.proposedName,
                    category: metadata.category,
                    artist: metadata.artist,
                    title: metadata.title,
                    album: metadata.album,
                    thumbnail: thumbnail
                )
                proposedChanges.append(change)
                processedFilesCount += 1
            } catch {
                let nsError = error as NSError
                print("Analysis Error: \(nsError.localizedDescription)")
                
                let fallback = ProposedChange(
                    originalURL: file,
                    proposedName: file.deletingPathExtension().lastPathComponent,
                    category: defaultCategory,
                    artist: nil, title: nil, album: nil,
                    thumbnail: thumbnail
                )
                proposedChanges.append(fallback)
                processedFilesCount += 1
            }
        }
        
        if !shouldStop && !proposedChanges.isEmpty {
            withAnimation {
                isProcessing = false
                isReviewing = true
            }
        } else {
            resetQueue()
        }
    }
    
    @MainActor
    private func executeChanges() async {
        withAnimation {
            isReviewing = false
            isProcessing = true
            shouldStop = false
        }
        
        totalFiles = proposedChanges.count
        processedFilesCount = 0
        let fileProcessor = FileProcessor()
        
        for change in proposedChanges {
            if shouldStop { break }
            statusMessage = "Organizing: \(change.proposedName)"
            
            do {
                let finalURL = try await fileProcessor.process(file: change.originalURL, with: change.toMetadata, createFolders: createSubfolders, applyTags: applyFinderTags)
                
                let record = ProcessedFileRecord(
                    originalURL: change.originalURL,
                    originalName: change.originalURL.lastPathComponent,
                    finalURL: finalURL,
                    category: change.category,
                    summary: change.proposedName
                )
                processedHistory.append(record)
                
                processedFilesCount += 1
            } catch {
                let nsError = error as NSError
                if nsError.domain == NSCocoaErrorDomain && nsError.code == 513 {
                    let folderURL = change.originalURL.deletingLastPathComponent()
                    if let securedFolder = await requestFolderAccess(for: folderURL) {
                        securedFolders.append(securedFolder)
                        do {
                            let finalURL = try await fileProcessor.process(file: change.originalURL, with: change.toMetadata, createFolders: createSubfolders, applyTags: applyFinderTags)
                            
                            let record = ProcessedFileRecord(
                                originalURL: change.originalURL,
                                originalName: change.originalURL.lastPathComponent,
                                finalURL: finalURL,
                                category: change.category,
                                summary: change.proposedName
                            )
                            processedHistory.append(record)
                            
                            processedFilesCount += 1
                        } catch {
                            lastError = "Failed to save: \(error.localizedDescription)"
                        }
                    } else {
                        lastError = "Permission to the folder was denied."
                        break
                    }
                } else {
                    lastError = "Error: \(error.localizedDescription)"
                }
            }
        }
        
        if !shouldStop {
            statusMessage = "Done!"
            if enableSounds { NSSound(named: "Glass")?.play() }
            if enableNotifications {
                sendNotification(title: "Media Organized!", body: "Successfully organized \(processedFilesCount) file(s).")
            }
            try? await Task.sleep(for: .seconds(2))
        }
        resetQueue()
    }
    
    private func sendNotification(title: String, body: String) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.sound = .default
            
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
    
    @MainActor
    private func resetQueue() {
        for url in securedURLs { url.stopAccessingSecurityScopedResource() }
        for folder in securedFolders { folder.stopAccessingSecurityScopedResource() }
        securedURLs.removeAll()
        securedFolders.removeAll()
        
        withAnimation {
            statusMessage = ""
            isProcessing = false
            isDownloadingModel = false
            isReviewing = false
            shouldStop = false
            rotationAngle = 0
            queuedFiles.removeAll()
            proposedChanges.removeAll()
        }
    }
}

// MARK: - ROW VIEW TO PREVENT CRASH
struct ReviewRow: View {
    @Binding var change: ProposedChange
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            if let thumb = change.thumbnail {
                Image(nsImage: thumb)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 44, height: 44)
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(Image(systemName: "doc").foregroundStyle(.secondary))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                TextField("Name", text: $change.proposedName)
                    .textFieldStyle(.plain)
                    .font(.body.bold())
                
                HStack {
                    Image(systemName: "folder")
                    TextField("Category", text: $change.category)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - NATIVE GLASS EFFECT
struct VisualEffectView: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.blendingMode = .behindWindow
        view.state = .active
        view.material = .underWindowBackground
        return view
    }
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

#Preview {
    ContentView()
}
