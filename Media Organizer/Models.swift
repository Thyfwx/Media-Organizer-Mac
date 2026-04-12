//
//  Models.swift
//  Media Organizer
//

import Foundation
import AppKit

// MARK: - CONFIG MODELS
public struct LLMConfig: Sendable {
    public var engineType: LLMEngineType
    public var endpoint: URL
    public var apiKey: String
    public var model: String
    public var namingTemplate: String
    public var customInstructions: String
    
    public init(engineType: LLMEngineType, endpoint: URL, apiKey: String, model: String, namingTemplate: String, customInstructions: String) {
        self.engineType = engineType
        self.endpoint = endpoint
        self.apiKey = apiKey
        self.model = model
        self.namingTemplate = namingTemplate
        self.customInstructions = customInstructions
    }
}

public enum LLMEngineType: Int, Codable, Sendable {
    case coreAI = 0      // Fast Heuristic (Unlimited)
    case proLocalAI = 1  // Local LLM (Limited/Heavy)
    case localOllama = 2
    case cloudAPI = 3
}

// MARK: - UI MODELS (Main Actor Isolated)
@MainActor
public struct ProposedChange: Identifiable {
    public let id = UUID()
    public let originalURL: URL
    public var proposedName: String
    public var category: String
    public var artist: String?
    public var title: String?
    public var album: String?
    public var thumbnail: NSImage?
    
    public var toMetadata: FileMetadata {
        FileMetadata(proposedName: proposedName, category: category, artist: artist, title: title, album: album)
    }
    
    public init(originalURL: URL, proposedName: String, category: String, artist: String?, title: String?, album: String?, thumbnail: NSImage?) {
        self.originalURL = originalURL
        self.proposedName = proposedName
        self.category = category
        self.artist = artist
        self.title = title
        self.album = album
        self.thumbnail = thumbnail
    }
}

@MainActor
public struct ProcessedFileRecord: Identifiable {
    public let id = UUID()
    public let dateProcessed: Date
    public let originalURL: URL
    public let originalName: String
    public let finalURL: URL
    public let category: String
    public let summary: String?
    
    public init(dateProcessed: Date = Date(), originalURL: URL, originalName: String, finalURL: URL, category: String, summary: String?) {
        self.dateProcessed = dateProcessed
        self.originalURL = originalURL
        self.originalName = originalName
        self.finalURL = finalURL
        self.category = category
        self.summary = summary
    }
}
