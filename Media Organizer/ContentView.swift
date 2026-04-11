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
import QuickLookThumbnailing

struct ProposedChange: Identifiable {
    let id = UUID()
    let originalURL: URL
    var proposedName: String
    var category: String
    var artist: String?
    var title: String?
    var album: String?
    var thumbnail: NSImage?
    
    var toMetadata: FileMetadata {
        FileMetadata(proposedName: proposedName, category: category, artist: artist, title: title, album: album)
    }
}

struct ProcessedFileRecord: Identifiable {
    let id = UUID()
    let originalURL: URL
    let originalName: String
    let finalURL: URL
}

struct ContentView: View {
    @State private var isDropTargeted = false
    @State private var queuedFiles: [URL] = []
    @State private var proposedChanges: [ProposedChange] = []
    
    @State private var processedHistory: [ProcessedFileRecord] = []
    @State private var showHistory = false
    
    @State private var securedURLs: [URL] = []
    @State private var securedFolders: [URL] = []
    
    @State private var isProcessing = false
    @State private var isReviewing = false
    @State private var isDownloadingModel = false
    @State private var shouldStop = false
    @State private var processedFilesCount = 0
    @State private var totalFiles = 0
    @State private var statusMessage = ""
    @State private var lastError: String? = nil
    
    @State private var rotationAngle: Double = 0
    @State private var gradientAnimation = false
    
    @AppStorage("aiMode") private var aiMode: Int = 0
    @AppStorage("namingTemplate") private var namingTemplate: String = "Descriptive Name"
    @AppStorage("customInstructions") private var customInstructions: String = ""
    @AppStorage("createSubfolders") private var createSubfolders: Bool = true
    @AppStorage("applyFinderTags") private var applyFinderTags: Bool = true
    @AppStorage("cloudEndpoint") private var cloudEndpoint: String = "https://api.openai.com/v1/chat/completions"
    @AppStorage("cloudApiKey") private var cloudApiKey: String = ""
    @AppStorage("cloudModel") private var cloudModel: String = "gpt-4o-mini"
    @AppStorage("localModel") private var localModel: String = "llama3.2"
    
    var body: some View {
        ZStack {
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
    
    // MARK: - UI COMPONENTS
    
    private var historyPopover: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Recently Organized")
                .font(.headline)
                .padding()
            
            Divider()
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(processedHistory.reversed()) { record in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(record.finalURL.lastPathComponent)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                Text("Was: \(record.originalName)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            
                            Button(action: { undoMove(for: record) }) {
                                Image(systemName: "arrow.uturn.backward")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.orange)
                            .help("Undo this change")
                            
                            Button(action: {
                                NSWorkspace.shared.activateFileViewerSelecting([record.finalURL])
                            }) {
                                Image(systemName: "magnifyingglass")
                            }
                            .buttonStyle(.plain)
                            .help("Show in Finder")
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 350, height: 350)
    }
    
    private var mainScreen: some View {
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
                Text(statusMessage)
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
                    
                    Button(action: { Task { await analyzeQueue() } }) {
                        Text("Analyze & Review")
                            .bold()
                            .frame(width: 140)
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
    }
    
    private var reviewScreen: some View {
        VStack(spacing: 0) {
            Text("Review Proposed Changes")
                .font(.title2.weight(.bold))
                .padding(.top, 40)
                .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(0..<proposedChanges.count, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(proposedChanges[index].originalURL.lastPathComponent)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                            }
                            
                            HStack(spacing: 12) {
                                if let thumb = proposedChanges[index].thumbnail {
                                    Image(nsImage: thumb)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 44, height: 44)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.secondary.opacity(0.2))
                                        .frame(width: 44, height: 44)
                                        .overlay(Image(systemName: "doc").foregroundStyle(.secondary))
                                }
                                
                                VStack(spacing: 4) {
                                    TextField("Proposed Name", text: $proposedChanges[index].proposedName)
                                        .textFieldStyle(.roundedBorder)
                                    
                                    if createSubfolders {
                                        TextField("Folder", text: $proposedChanges[index].category)
                                            .textFieldStyle(.roundedBorder)
                                    }
                                }
                            }
                        }
                        .padding(12)
                        .background(Color.primary.opacity(0.05))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            Divider().padding(.vertical, 10)
            
            HStack {
                Button(role: .cancel, action: {
                    queuedFiles = proposedChanges.map { $0.originalURL }
                    proposedChanges.removeAll()
                    withAnimation { isReviewing = false }
                }) {
                    Text("Cancel")
                        .frame(width: 80)
                }
                .controlSize(.large)
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button(action: { Task { await executeChanges() } }) {
                    Text("Confirm & Organize")
                        .bold()
                        .frame(width: 160)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
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
            guard let pdf = PDFDocument(url: file), let page = pdf.page(at: 0), let text = page.string else { return nil }
            return String(text.prefix(1500))
            
        } else if ["txt", "md", "csv", "json"].contains(ext) {
            guard let text = try? String(contentsOf: file, encoding: .utf8) else { return nil }
            return String(text.prefix(1500))
            
        } else if ["png", "jpg", "jpeg", "heic", "tiff"].contains(ext) {
            guard let imageSource = CGImageSourceCreateWithURL(file as CFURL, nil),
                  let cgImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else { return nil }
            
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            let textRequest = VNRecognizeTextRequest()
            textRequest.recognitionLevel = .accurate
            
            let classifyRequest = VNClassifyImageRequest()
            
            try? requestHandler.perform([textRequest, classifyRequest])
            
            var imageDescription = ""
            if let text = textRequest.results?.compactMap({ $0.topCandidates(1).first?.string }).joined(separator: " "), !text.isEmpty {
                imageDescription += "Text in image: \(text)\n"
            }
            if let classifications = classifyRequest.results?.filter({ $0.hasMinimumRecall(0.7, forPrecision: 0.7) }).prefix(4).map({ $0.identifier }).joined(separator: ", ") {
                imageDescription += "Image looks like: \(classifications)"
            }
            return String(imageDescription.prefix(1500))
            
        } else if ["mp4", "mov", "m4a", "mp3", "wav"].contains(ext) {
            let asset = AVURLAsset(url: file)
            var mediaInfo = "Media File."
            
            if let duration = try? await asset.load(.duration) {
                mediaInfo += " Duration: \(Int(CMTimeGetSeconds(duration))) seconds."
            }
            let formats = try? await asset.load(.availableMetadataFormats)
            for format in formats ?? [] {
                if let metadata = try? await asset.loadMetadata(for: format) {
                    for item in metadata {
                        if let key = item.commonKey?.rawValue, let val = try? await item.load(.stringValue) {
                            mediaInfo += " \(key): \(val)."
                        }
                    }
                }
            }
            return mediaInfo
        }
        return nil
    }
    
    private func analyzeQueue() async {
        isProcessing = true
        shouldStop = false
        proposedChanges.removeAll()
        totalFiles = queuedFiles.count
        processedFilesCount = 0
        
        let config: LLMConfig
        if aiMode == 0 || aiMode == 1 {
            config = LLMConfig(endpoint: URL(string: "http://localhost:11434/v1/chat/completions")!, apiKey: "local", model: localModel, namingTemplate: namingTemplate, customInstructions: customInstructions)
        } else {
            config = LLMConfig(endpoint: URL(string: cloudEndpoint) ?? URL(string: "https://api.openai.com/v1/chat/completions")!, apiKey: cloudApiKey, model: cloudModel, namingTemplate: namingTemplate, customInstructions: customInstructions)
        }
        
        let llm = LLMService(config: config)
        
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
            if shouldStop { break }
            let file = queuedFiles.removeFirst()
            statusMessage = "Analyzing: \(file.lastPathComponent)"
            
            if aiMode == 2 && cloudApiKey.isEmpty {
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
                let fallback = ProposedChange(
                    originalURL: file,
                    proposedName: file.deletingPathExtension().lastPathComponent,
                    category: "Unsorted",
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
                
                let record = ProcessedFileRecord(originalURL: change.originalURL, originalName: change.originalURL.lastPathComponent, finalURL: finalURL)
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
                            
                            let record = ProcessedFileRecord(originalURL: change.originalURL, originalName: change.originalURL.lastPathComponent, finalURL: finalURL)
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
            NSSound(named: "Glass")?.play()
            try? await Task.sleep(for: .seconds(2))
        }
        resetQueue()
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
            isReviewing = false
            shouldStop = false
            rotationAngle = 0
            queuedFiles.removeAll()
            proposedChanges.removeAll()
        }
    }
}

#Preview {
    ContentView()
}
