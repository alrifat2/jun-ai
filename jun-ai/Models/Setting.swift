//  Setting.swift
//  jun-ai
//
//  Created by Al Rifat on 4/24/25.
//

import SwiftData
import Foundation

@Model
final class Setting {
    @Attribute(.unique) var id: String
    var aiKey: String
    var createdAt: Date
    
    init(id: String = UUID().uuidString, aiKey: String = "", createdAt: Date = Date()) {
        self.id = id
        self.aiKey = aiKey
        self.createdAt = createdAt
    }
}
