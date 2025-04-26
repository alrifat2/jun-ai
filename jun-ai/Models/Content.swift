//
//  Content.swift
//  jun-ai
//
//  Created by Al Rifat on 4/24/25.
//

import SwiftData
import Foundation

enum ContentType: String, Codable {
    case youtube
    case audio
    case document
}

@Model
final class Content {
    var id: String
    var title: String
    var contentType: ContentType
    var sourceUrl: String?  // URL for YouTube
    var createdAt: Date
    var lastUpdatedAt: Date
    var originalTranscript: String?
    var summary: String?
    
    // Relationships
    @Relationship(deleteRule: .nullify)
    var folder: Folder?
    
    var duration: TimeInterval?   // For audio/video
    var pageCount: Int?           // For documents
    
    init(id: String = UUID().uuidString,
         title: String,
         contentType: ContentType,
         sourceUrl: String? = nil,
         createdAt: Date = Date(),
         folder: Folder? = nil) {
        self.id = id
        self.title = title
        self.contentType = contentType
        self.sourceUrl = sourceUrl
        self.createdAt = createdAt
        self.lastUpdatedAt = createdAt
        self.folder = folder
    }
}
