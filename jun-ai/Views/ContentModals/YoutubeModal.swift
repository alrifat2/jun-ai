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
    
    @State private var url = ""
    
    @Environment(\.modelContext) private var modelContext    
    private var youtubeViewModal: YoutubeModalViewModel {
        YoutubeModalViewModel(modelContext: modelContext)
    }
    
    var onProcess: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
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

            HStack {
                Text("YouTube Video")
                    .font(.title2)
                    .fontWeight(.bold)            }
            
            Text("Extract from YouTube videos by providing a link. Jun AI will analyze the content and generate summaries, key points, and more.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
                .padding(.bottom, 8)
            
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
                
                let summary = await youtubeViewModal.getSummary(transcript: transcriptText)
                if let summary = summary {
                    let content = await youtubeViewModal.createContent(transcript: transcriptText, youtubeUrl: trimmedUrl, summary: summary)
                    if content != nil {
                        onProcess(trimmedUrl)
                    }
                }
            } catch {
                print("❌ Transcript fetch failed:", error.localizedDescription)
            }
    
            isProcessing = false
            dismiss()
        }
    }
}

#Preview {
    YoutubeModal(onProcess: { _ in })
}
