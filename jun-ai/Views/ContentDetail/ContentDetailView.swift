//
//  ContentDetailView.swift
//  jun-ai
//
//  Created by Al Rifat on 4/26/25.
//

import SwiftUI
import SwiftData
import MarkdownUI
import AppKit

struct ContentDetailView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Binding var navigationPath: NavigationPath
    
    @FocusState private var isInputFocused: Bool
    
    enum SidebarItem: String, CaseIterable, Identifiable {
        case summary = "Summary"
        case flashcards = "Flashcards"
        case quiz = "Quiz"
        case transcript = "Transcript"
        
        var id: String { self.rawValue }
        
        var icon: String {
            switch self {
            case .summary: return "text.redaction"
            case .flashcards: return "rectangle.stack.fill"
            case .quiz: return "questionmark.circle.fill"
            case .transcript: return "doc.text"
            }
        }
    }
    
    let content: Content
    @State private var selectedItem: SidebarItem = .summary
    @State private var showChatPanel: Bool = true
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(content.title)
                    .font(.headline)
                    .lineLimit(2)
                    .padding(.horizontal)
                    .padding(.vertical, 10.3)
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(SidebarItem.allCases) { item in
                            Button {
                                selectedItem = item
                                isInputFocused = false
                            } label: {
                                HStack {
                                    Image(systemName: item.icon)
                                        .frame(width: 24)
                                    Text(item.rawValue)
                                        .font(.body)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(selectedItem == item ?
                                              Color.accentColor.opacity(0.2) :
                                              Color.clear)
                                        .padding(.horizontal, 4)
                                )
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(selectedItem == item ? .accentColor : .primary)
                            .contentShape(Rectangle())
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 4)
                }
            }
            .frame(width: 220)
            .background(Color(NSColor.windowBackgroundColor).opacity(0.8))
            .onTapGesture {
                isInputFocused = false
            }
            
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        Text(selectedItem.rawValue)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Label(content.contentType.rawValue.capitalized, systemImage: contentTypeIcon)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        Text("Created: \(formattedDate(content.createdAt))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        if let sourceUrl = content.sourceUrl {
                            Link("Source", destination: URL(string: sourceUrl) ?? URL(string: "https://youtube.com")!)
                                .font(.subheadline)
                        }
                        
                        Button(action: {
                            withAnimation {
                                showChatPanel.toggle()
                            }
                            isInputFocused = false
                        }) {
                            Image(systemName: showChatPanel ? "message.fill" : "message")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding([.top, .horizontal])
                    
                    Divider()
                }
                .background(Color(NSColor.windowBackgroundColor))
                
                ScrollView {
                    ZStack {
                        switch selectedItem {
                        case .summary:
                            summaryView
                        case .flashcards:
                            flashcardsView
                        case .quiz:
                            quizView
                        case .transcript:
                            transcriptView
                        }
                        
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                isInputFocused = false
                            }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                .scrollIndicators(.hidden)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(NSColor.windowBackgroundColor))
            
            if showChatPanel {
                ChatPanel(showChatPanel: $showChatPanel, content: content)
            }
        }
        .background(
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = false
                }
        )
    }
    
    private var summaryView: some View {
        ScrollView {
            if let summary = content.summary {
                Markdown(summary)
                    .padding()
            } else {
                Text("No summary available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
        .scrollIndicators(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ?
                      Color(.textBackgroundColor).opacity(0.3) :
                      Color(.textBackgroundColor).opacity(0.5))
        )
        .padding(.horizontal)
    }
    
    private var transcriptView: some View {
        ScrollView {
            if let transcript = content.originalTranscript {
                Text(transcript)
                    .font(.body)
                    .padding()
                    .textSelection(.enabled)
            } else {
                Text("No transcript available")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
            }
        }
        .scrollIndicators(.hidden)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ?
                      Color(.textBackgroundColor).opacity(0.3) :
                      Color(.textBackgroundColor).opacity(0.5))
        )
        .padding(.horizontal)
    }
    
    private var flashcardsView: some View {
        VStack {
            Text("Flashcards feature coming soon")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ?
                      Color(.textBackgroundColor).opacity(0.3) :
                      Color(.textBackgroundColor).opacity(0.5))
        )
        .padding(.horizontal)
    }
    
    private var quizView: some View {
        VStack {
            Text("Quiz feature coming soon")
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(colorScheme == .dark ?
                      Color(.textBackgroundColor).opacity(0.3) :
                      Color(.textBackgroundColor).opacity(0.5))
        )
        .padding(.horizontal)
    }
    
    private var contentTypeIcon: String {
        switch content.contentType {
        case .youtube:
            return "play.rectangle.fill"
        case .audio:
            return "waveform"
        case .document:
            return "doc.text.fill"
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
