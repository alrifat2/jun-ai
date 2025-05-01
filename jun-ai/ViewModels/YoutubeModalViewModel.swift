//
//  YoutubeModalViewModel.swift
//  jun-ai
//
//  Created by Al Rifat on 4/25/25.
//

import SwiftData
import Foundation

@MainActor
class YoutubeModalViewModel: ObservableObject {
    @Published var entries: [TranscriptEntry] = []
    @Published var error: String?
    
    private var modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func getTitle(transcript: String) async -> String? {
        do {
            let settingService = SettingService(context: modelContext)
            guard let apiKey = settingService.getApiKey(), !apiKey.isEmpty else {
                print("❌ No valid API key found.")
                return nil
            }
            
            let aiService = AIService(apiKey: apiKey)
            let title = try await aiService.generateYoutubeTitle(transcript: transcript)
            
            return title.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            self.error = error.localizedDescription
            return nil
        }
        
    }
    
    func getSummary(transcript: String) async -> String? {
        do {
            let settingService = SettingService(context: modelContext)
            guard let apiKey = settingService.getApiKey(), !apiKey.isEmpty else {
                print("❌ No valid API key found.")
                return nil
            }
            
            let aiService = AIService(apiKey: apiKey)
            let summaryMarkdown = try await aiService.generateYoutubeSummary(transcript: transcript)
            
            return summaryMarkdown
        } catch {
            self.error = error.localizedDescription
            return nil
        }
    }
    
    func createContent(transcript: String, youtubeUrl: String, summary: String) async -> Content? {
        do {
            let contentTitle = await getTitle(transcript: transcript) ?? "YouTube Video"
            
            let content = Content(
                title: contentTitle,
                contentType: .youtube,
                sourceUrl: youtubeUrl
            )
            
            content.summary = summary
            content.originalTranscript = transcript
            
            modelContext.insert(content)
            try modelContext.save()
            
            return content
        } catch {
            self.error = error.localizedDescription
            print("❌ Failed to create content:", error.localizedDescription)
            return nil
        }
    }
}
