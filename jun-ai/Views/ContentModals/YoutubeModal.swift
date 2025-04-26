//
//  YoutubeModal.swift
//  jun-ai
//
//  Created by Al Rifat on 4/24/25.
//

import SwiftUI

struct YoutubeModal: View {
    @Environment(\.dismiss) private var dismiss
    @State private var youtubeUrl: String = ""
    @State private var isProcessing: Bool = false
    @State private var errorMessage: String? = nil
    
    @StateObject var viewModal = YoutubeModalViewModel()
    @State private var url = ""
    
    @Environment(\.modelContext) private var modelContext
    
    var onProcess: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header with title and close button
            HStack {
                Text("YouTube Video")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            // Description
            Text("Extract from YouTube videos by providing a link. Jun AI will analyze the content and generate summaries, key points, and more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 8)
            
            // URL input field
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter YouTube URL")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "link")
                        .foregroundStyle(.secondary)
                    
                    TextField("https://www.youtube.com/watch?v=...", text: $youtubeUrl)
                        .textFieldStyle(.plain)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.textBackgroundColor).opacity(0.5))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                
                if let error = errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                            .font(.caption)
                        
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
            }
            // Action buttons
            HStack {
                Spacer()
                
                Button {
                    processYoutubeUrl()
                } label: {
                    HStack {
                        if isProcessing {
                            ProgressView()
                                .frame(width: 8, height: 8)
                                .padding(.trailing, 4)
                        }
                        Text("Process Video")
                    }
                    .frame(minWidth: 140)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(youtubeUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
            }
        }
        .padding(24)
        .frame(width: 550, height: 320)
    }
    
    private func processYoutubeUrl() {
        let trimmedUrl = youtubeUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedUrl.contains("youtube.com") || trimmedUrl.contains("youtu.be") else {
            errorMessage = "Please enter a valid YouTube URL"
            return
        }
        
        errorMessage = nil
        isProcessing = true
        
        Task {
            do {
                let transcript = try await YoutubeTranscript.fetchTranscript(from: trimmedUrl)
                let transcriptText = transcript.map { $0.text }.joined(separator: " ")
//                for entry in transcript {
//                    print("[\(entry.offset)s - \(entry.offset + entry.duration)s] \(entry.text)")
//                }
                
                let settingService = SettingService(context: modelContext)
                guard let apiKey = settingService.getApiKey(), !apiKey.isEmpty else {
                    print("❌ No valid API key found.")
                    return
                }
                
                print(apiKey)
                
                do {
                    let aiService = AIService(apiKey: apiKey)
                    let summaryMarkdown = try await aiService.generateYoutubeSummary(transcript: transcriptText)
                    print(summaryMarkdown)
                } catch {
                    print("❌ AI Summary Generation Failed:", error.localizedDescription)
                }
                
            } catch {
                print("❌ Transcript fetch failed:", error.localizedDescription)
            }

            isProcessing = false
            onProcess(trimmedUrl)
            dismiss()
        }
    }
    
    
}

#Preview {
    YoutubeModal(onProcess: { _ in })
}
