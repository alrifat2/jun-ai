//
//  ChatPanel.swift
//  jun-ai
//
//  Created by Al Rifat on 4/26/25.
//

import SwiftUI
import AppKit
import SwiftData

struct ChatPanel: View {
    @Binding var showChatPanel: Bool
    @FocusState private var isInputFocused: Bool
    
    @State private var chatPanelWidth: CGFloat = 300
    @State private var isDraggingDivider: Bool = false
    @State private var chatInput: String = ""
    @State private var chatMessages: [ChatMessage] = []
    @State private var isStreaming: Bool = false
    @State private var streamedResponse: String = ""
    
    let content: Content
    @Environment(\.modelContext) private var modelContext
    
    struct ChatMessage: Identifiable {
        let id = UUID()
        let content: String
        let isUser: Bool
        let timestamp = Date()
    }
    
    private var apiChatHistory: [[String: Any]] {
        chatMessages.map { message in
            return [
                "role": message.isUser ? "user" : "model",
                "parts": [
                    ["text": message.content]
                ]
            ]
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.gray.opacity(isDraggingDivider ? 0.5 : 0.2))
                    .frame(width: 1)
                
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.gray.opacity(0.6))
                        .frame(width: 4, height: 30)
                    Spacer()
                }
            }
            .frame(width: 20)
            .contentShape(Rectangle())
            .onHover { hovering in
                if hovering {
                    NSCursor.resizeLeftRight.push()
                } else {
                    NSCursor.pop()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        isDraggingDivider = true
                        let newWidth = chatPanelWidth - value.translation.width
                        chatPanelWidth = min(max(250, newWidth), 500)
                        NSCursor.resizeLeftRight.push()
                        isInputFocused = false
                    }
                    .onEnded { _ in
                        isDraggingDivider = false
                        NSCursor.pop()
                        DispatchQueue.main.async {
                            NSCursor.current.set()
                        }
                    }
            )
            
            VStack(spacing: 0) {
                HStack {
                    Text("Chat with Jun AI")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            showChatPanel = false
                        }
                        isInputFocused = false
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .padding(.bottom, 4.5)
                .contentShape(Rectangle())
                .onTapGesture {
                    isInputFocused = false
                }
                
                Divider()
                
                ScrollViewReader { scrollView in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            if chatMessages.isEmpty && !isStreaming {
                                VStack(spacing: 16) {
                                    Image(systemName: "bubble.left.and.bubble.right")
                                        .font(.largeTitle)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Ask Jun AI about this content")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("NOTE: Chat history are not saved, and deleted if you go back")
                                        .font(.caption)
                                        .foregroundStyle(.tertiary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    isInputFocused = false
                                }
                            } else {
                                ForEach(chatMessages) { message in
                                    chatBubble(message)
                                        .id(message.id)
                                }
                                .padding(.horizontal)
                                
                                if isStreaming {
                                    HStack {
                                        Text(streamedResponse)
                                            .padding(10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .fill(Color(NSColor.controlBackgroundColor))
                                            )
                                            .id("streamingMessage")
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                }
                            }
                        }
                        .padding(.vertical)
                        .onChange(of: chatMessages.count) { _, _ in
                            if let lastMessage = chatMessages.last {
                                withAnimation {
                                    scrollView.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: streamedResponse) { _, _ in
                            withAnimation {
                                scrollView.scrollTo("streamingMessage", anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                HStack(spacing: 8) {
                    TextField("Ask a question...", text: $chatInput)
                        .textFieldStyle(.plain)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(NSColor.textBackgroundColor))
                        )
                        .focused($isInputFocused)
                        .disabled(isStreaming)
                        .onSubmit {
                            if !isStreaming && !chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                sendMessage()
                            }
                        }
                    
                    Button(action: sendMessage) {
                        if isStreaming {
                            Image(systemName: "stop.circle.fill")
                                .font(.title3)
                                .foregroundColor(.red)
                        } else {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title3)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!isStreaming && chatInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding()
            }
        }
        .frame(width: chatPanelWidth)
        .background(Color(NSColor.windowBackgroundColor).opacity(0.9))
    }
    
    private func chatBubble(_ message: ChatMessage) -> some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.content)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(message.isUser ?
                              Color.accentColor.opacity(0.8) :
                              Color(NSColor.controlBackgroundColor))
                )
                .foregroundStyle(message.isUser ? .white : .primary)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
    
    private func sendMessage() {
        if isStreaming {
            isStreaming = false
            if !streamedResponse.isEmpty {
                chatMessages.append(ChatMessage(content: streamedResponse, isUser: false))
                streamedResponse = ""
            }
            return
        }
        
        let trimmedInput = chatInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedInput.isEmpty else { return }
        
        chatMessages.append(ChatMessage(content: trimmedInput, isUser: true))
        chatInput = ""
        
        let history = apiChatHistory
        
        streamResponse(history: history)
    }
    
    private func streamResponse(history: [[String: Any]]) {
        isStreaming = true
        streamedResponse = ""
        
        Task {
            do {
                let settingService = SettingService(context: modelContext)
                guard let apiKey = settingService.getApiKey(), !apiKey.isEmpty else {
                    streamedResponse = "Error: API key not found. Please set up your API key in settings."
                    chatMessages.append(ChatMessage(content: streamedResponse, isUser: false))
                    isStreaming = false
                    streamedResponse = ""
                    return
                }
                
                let aiService = AIService(apiKey: apiKey)
                let stream = try await aiService.streamGenerateChat(
                    chatHistory: history,
                    summary: content.summary
                )
                
                for try await chunk in stream {
                    if !isStreaming {
                        break
                    }
                    
                    streamedResponse += chunk
                    
                    try? await Task.sleep(nanoseconds: 10_000_000)
                }
                
                if isStreaming {
                    chatMessages.append(ChatMessage(content: streamedResponse, isUser: false))
                    isStreaming = false
                    streamedResponse = ""
                }
            } catch {
                streamedResponse = "Error: \(error.localizedDescription)"
                chatMessages.append(ChatMessage(content: streamedResponse, isUser: false))
                isStreaming = false
                streamedResponse = ""
            }
        }
    }
}
