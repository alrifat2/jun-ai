//
//  YoutubeModalViewModel.swift
//  jun-ai
//
//  Created by Al Rifat on 4/25/25.
//

import Foundation

@MainActor
class YoutubeModalViewModel: ObservableObject {
    @Published var entries: [TranscriptEntry] = []
    @Published var error: String?
    
    func getTranscript(for url: String) async {
        Task {
            do {
                let result = try await YoutubeTranscript.fetchTranscript(from: url)
                entries = result
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
