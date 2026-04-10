//
//  FileProcessor.swift
//  Media Organizer
//

import Foundation
import AVFoundation

actor FileProcessor {
    func process(file url: URL, with metadata: FileMetadata) async throws {
        let ext = url.pathExtension.lowercased()
        let isMedia = ["mp4", "m4a", "mov"].contains(ext)
        
        // Clean proposed name of invalid file path characters
        let safeName = metadata.proposedName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        if isMedia {
            try await applyMetadataAndRename(sourceURL: url, safeName: safeName)
        } else {
            // SANDBOX FIX: Instead of moving the file, we change its "name" resource!
            var mutableURL = url
            var resourceValues = URLResourceValues()
            resourceValues.name = "\(safeName).\(ext)"
            try mutableURL.setResourceValues(resourceValues)
        }
    }
    
    private func applyMetadataAndRename(sourceURL: URL, safeName: String) async throws {
        let asset = AVURLAsset(url: sourceURL)
        
        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetPassthrough) else {
            throw URLError(.cannotCreateFile)
        }
        
        // Output to a temporary file first
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension(sourceURL.pathExtension)
        
        exportSession.outputURL = tempURL
        exportSession.outputFileType = sourceURL.pathExtension.lowercased() == "m4a" ? .m4a : .mp4
        
        await exportSession.export()
        
        if exportSession.status == .completed {
            // SANDBOX FIX: Replace the contents of the original file with our new temp file
            let resultingURL = try FileManager.default.replaceItemAt(sourceURL, withItemAt: tempURL)
            
            // Now rename the file using the secure resource API
            var resourceValues = URLResourceValues()
            resourceValues.name = "\(safeName).\(sourceURL.pathExtension)"
            
            var finalURL = resultingURL ?? sourceURL
            try finalURL.setResourceValues(resourceValues)
            
        } else {
            throw exportSession.error ?? URLError(.unknown)
        }
    }
}
