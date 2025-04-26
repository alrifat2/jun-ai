//
//  jun_aiApp.swift
//  jun-ai
//
//  Created by Al Rifat on 4/24/25.
//

import SwiftUI
import SwiftData

@main
struct jun_aiApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Content.self,
            Folder.self,
            Setting.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
    }
}
