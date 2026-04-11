//
//  FileMetadata.swift
//  Media Organizer
//

import Foundation

/// A pure data model for file information.
/// Keeping this strictly Foundation-only and using manual conformance
/// to ensure it is NOT isolated to the MainActor in a Swift 6 environment.
public struct FileMetadata: Sendable {
    public var proposedName: String
    public var category: String
    public var artist: String?
    public var title: String?
    public var album: String?
    
    public init(proposedName: String, category: String, artist: String? = nil, title: String? = nil, album: String? = nil) {
        self.proposedName = proposedName
        self.category = category
        self.artist = artist
        self.title = title
        self.album = album
    }
}

// Explicitly separate Codable to avoid actor-isolated conformance inference
extension FileMetadata: Decodable {
    private enum CodingKeys: String, CodingKey {
        case proposedName, category, artist, title, album
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = try container.decode(String.self, forKey: .proposedName)
        let cat = try container.decode(String.self, forKey: .category)
        let art = try container.decodeIfPresent(String.self, forKey: .artist)
        let tit = try container.decodeIfPresent(String.self, forKey: .title)
        let alb = try container.decodeIfPresent(String.self, forKey: .album)
        
        self.init(proposedName: name, category: cat, artist: art, title: tit, album: alb)
    }
}

extension FileMetadata: Encodable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(proposedName, forKey: .proposedName)
        try container.encode(category, forKey: .category)
        try container.encode(artist, forKey: .artist)
        try container.encode(title, forKey: .title)
        try container.encode(album, forKey: .album)
    }
}
