//
//  Setting.swift
//  jun-ai
//
//  Created by Al Rifat on 4/26/25.
//

import SwiftData
import Foundation

class SettingService {
    private let context: ModelContext
    
    init(context: ModelContext) {
        self.context = context
    }
    
    func getApiKey() -> String? {
        let fetchDescriptor = FetchDescriptor<Setting>(sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        
        do {
            let settings = try context.fetch(fetchDescriptor)
            return settings.first?.aiKey
        } catch {
            print("❌ Failed to fetch Setting:", error.localizedDescription)
            return nil
        }
    }
}
