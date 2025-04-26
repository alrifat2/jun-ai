//
//  DashboardView.swift
//  jun-ai
//
//  Created by Al Rifat on 4/24/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    @Query private var folders: [Folder]
    @Query private var contents: [Content]
    @State private var showAddFolderDialog = false
    @State private var showDeleteConfirmation = false
    @State private var showRenameDialog = false
    @State private var showYoutubeModal = false
    @State private var newFolderName = ""
    @State private var selectedFolder: Folder?
    
    private var viewModel: DashboardViewModel {
        DashboardViewModel(modelContext: modelContext)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Dashboard")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.top, -4)
                .padding(.bottom, 4)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 300, maximum: 350), spacing: 20)], spacing: 20) {
                // Audio Card
                ContentCard(
                    title: "Upload Audio",
                    description: "Import audio files directly to transcribe and analyze.",
                    icon: "waveform",
                    color: .blue
                ) {
                    print("Audio upload tapped")
                }
                
                // Document Card
                ContentCard(
                    title: "Upload Document",
                    description: "Import PDF, or Word for analysis and summarization.",
                    icon: "doc.text",
                    color: .green
                ) {
                    print("Document upload tapped")
                }
                
                // YouTube Card
                ContentCard(
                    title: "YouTube Video",
                    description: "Analyze YouTube videos by pasting a URL for extraction.",
                    icon: "play.rectangle",
                    color: .red
                ) {
                    showYoutubeModal = true
                }
            }
            .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("All Contents")
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                if contents.isEmpty {
                    Text("No content yet")
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(contents) { content in
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(content.title)
                                            .font(.headline)
                                        
                                        Text(content.contentType.rawValue.capitalized)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(formatDate(content.createdAt))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(colorScheme == .dark ? 
                                              Color(.controlBackgroundColor) : 
                                              Color(.controlBackgroundColor).opacity(0.5))
                                )
                            }
                        }
                    }
                    .frame(maxHeight: 300)
                }
            }
        }
        .padding(.top, 0)
        .padding([.horizontal, .bottom], 20)
        .frame(minWidth: 500, idealWidth: 800, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .sheet(isPresented: $showYoutubeModal) {
            YoutubeModal { youtubeUrl in
                print("Processing YouTube URL: \(youtubeUrl)")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    DashboardView()
}
