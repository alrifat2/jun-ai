//
//  DashboardViewModel.swift
//  jun-ai
//
//  Created by Al Rifat on 4/24/25.
//

import SwiftData
import Foundation

class DashboardViewModel: ObservableObject {
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createFolder(folderName: String) {
        let name = folderName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let newFolder = Folder(name: name)
        modelContext.insert(newFolder)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save folder: \(error)")
        }
    }
    
    func renameFolder(folder: Folder?, newName: String) {
        guard let folder else { return }
        
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        
        folder.name = name
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to rename folder: \(error)")
        }
    }
    
    func deleteFolder(folder: Folder?) {
        guard let folder else { return }
        
        modelContext.delete(folder)
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete folder: \(error)")
        }
    }
}
