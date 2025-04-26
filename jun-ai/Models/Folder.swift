//
//  Folder.swift
//  jun-ai
//
//  Created by Al Rifat on 4/24/25.
//

import SwiftData
import Foundation

@Model
final class Folder {
    var id: String
    var name: String
    var createdAt: Date
    
    // Relationships
    @Relationship(deleteRule: .cascade, inverse: \Content.folder)
    var contents: [Content] = []
    
    init(id: String = UUID().uuidString, name: String, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
    }
}
