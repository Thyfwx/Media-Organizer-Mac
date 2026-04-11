//
//  FileProcessor.swift
//  Media Organizer
//

import Foundation
import AVFoundation

actor FileProcessor {
    // UPGRADED: Now accepts user settings and returns the final URL for our History Log!
    func process(file url: URL, with metadata: FileMetadata, createFolders: Bool, applyTags: Bool) async throws -> URL {
        let ext = url.pathExtension.lowercased()
        let isMedia = ["mp4", "m4a", "mov"].contains(ext)
        
        let safeName = metadata.proposedName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
            
        let safeCategory = metadata.category
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        let baseDirectory = url.deletingLastPathComponent()
        
        // Respect the user's setting to create subfolders or not
        let finalDirectory: URL
        if createFolders {
            finalDirectory = baseDirectory.appendingPathComponent(safeCategory)
            if !FileManager.default.fileExists(atPath: finalDirectory.path) {
                try FileManager.default.createDirectory(at: finalDirectory, withIntermediateDirectories: true)
            }
        } else {
            finalDirectory = baseDirectory
        }
        
        let finalURL = finalDirectory.appendingPathComponent("\(safeName).\(ext)")

        if isMedia {
            try await applyMetadataAndMove(sourceURL: url, destinationURL: finalURL, metadata: metadata)
        } else {
            if url != finalURL {
                if FileManager.default.fileExists(atPath: finalURL.path) {
                    try FileManager.default.removeItem(at: finalURL)
                }
                try FileManager.default.moveItem(at: url, to: finalURL)
            }
        }
        
        // NEW FEATURE: Apply Native macOS Finder Tags!
        if applyTags {
            var resourceValues = URLResourceValues()
            // We apply the AI's category as a native, searchable Mac Finder Tag
            resourceValues.tagNames = [safeCategory]
            var taggedURL = finalURL
            try taggedURL.setResourceValues(resourceValues)
        }
        
        return finalURL
    }
    
    private func applyMetadataAndMove(sourceURL: URL, destinationURL: URL, metadata: FileMetadata) async throws {
        let asset = AVURLAsset(url: sourceURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw URLError(.cannotCreateFile)
        }
        
        var metadataItems: [AVMetadataItem] = []
        
        func createItem(identifier: AVMetadataIdentifier, value: String) -> AVMetadataItem {
            let item = AVMutableMetadataItem()
            item.identifier = identifier
            item.value = value as NSString
            item.dataType = kCMMetadataBaseDataType_UTF8 as String
            return item
        }
        
        if let artist = metadata.artist { metadataItems.append(createItem(identifier: .commonIdentifierArtist, value: artist)) }
        if let title = metadata.title { metadataItems.append(createItem(identifier: .commonIdentifierTitle, value: title)) }
        if let album = metadata.album { metadataItems.append(createItem(identifier: .commonIdentifierAlbumName, value: album)) }
        
        exportSession.metadata = metadataItems
        
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(sourceURL.pathExtension)
        
        exportSession.outputURL = tempURL
        exportSession.outputFileType = sourceURL.pathExtension.lowercased() == "m4a" ? .m4a : .mp4
        
        await exportSession.export()
        
        if exportSession.status == .completed {
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: tempURL, to: destinationURL)
            
            if sourceURL != destinationURL {
                try? FileManager.default.removeItem(at: sourceURL)
            }
        } else {
            throw exportSession.error ?? URLError(.unknown)
        }
    }
}
