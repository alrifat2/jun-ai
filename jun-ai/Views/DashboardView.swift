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
    @State private var navigationPath = NavigationPath()
    @State private var selectedContent: Content?
    @State private var newContentName = ""
    @State private var showRenameContentDialog = false
    @State private var showDeleteContentConfirmation = false
    
    private var viewModel: DashboardViewModel {
        DashboardViewModel(modelContext: modelContext)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
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
                                    Button {
                                        navigationPath.append(content)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                HStack(spacing: 6) {
                                                    Text(content.title)
                                                        .font(.headline)
                                                        .foregroundStyle(.primary)
                                                    
                                                    if let folder = content.folder {
                                                        HStack(spacing: 2) {
                                                            Text("in")
                                                                .font(.caption)
                                                                .foregroundStyle(.secondary)
                                                            
                                                            Image(systemName: "folder.fill")
                                                                .font(.caption)
                                                                .foregroundStyle(.secondary)
                                                            
                                                            Text(folder.name)
                                                                .font(.caption)
                                                                .fontWeight(.medium)
                                                                .foregroundStyle(.secondary)
                                                        }
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(
                                                            Capsule()
                                                                .fill(Color(.controlBackgroundColor).opacity(colorScheme == .dark ? 0.3 : 0.5))
                                                        )
                                                    }
                                                }
                                                
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
                                    .buttonStyle(PlainButtonStyle())
                                    .contextMenu {
                                        Button {
                                            selectedContent = content
                                            newContentName = content.title
                                            showRenameContentDialog = true
                                        } label: {
                                            Label("Rename", systemImage: "pencil")
                                        }
                                        
                                        Menu {
                                            if content.folder != nil {
                                                Button {
                                                    moveContent(content, to: nil)
                                                } label: {
                                                    Label("Remove from Folder", systemImage: "folder.badge.minus")
                                                }
                                                
                                                Divider()
                                            }
                                            
                                            if folders.isEmpty {
                                                Text("No folders available")
                                            } else {
                                                ForEach(folders) { folder in
                                                    Button {
                                                        moveContent(content, to: folder)
                                                    } label: {
                                                        Label(folder.name, systemImage: "folder")
                                                    }
                                                    .disabled(content.folder?.id == folder.id)
                                                }
                                            }
                                            
                                            Divider()
                                            
                                            Button {
                                                selectedContent = content
                                                showAddFolderDialog = true
                                            } label: {
                                                Label("New Folder...", systemImage: "folder.badge.plus")
                                            }
                                        } label: {
                                            Label("Move to Folder", systemImage: "folder")
                                        }
                                        
                                        Divider()
                                        
                                        Button(role: .destructive) {
                                            selectedContent = content
                                            showDeleteContentConfirmation = true
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(.top, 0)
            .padding([.horizontal, .bottom], 20)
            .frame(minWidth: 500, idealWidth: 800, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
            .sheet(isPresented: $showYoutubeModal) {
                YoutubeModal { youtubeUrl in
                    if let latestContent = contents.sorted(by: { $0.createdAt > $1.createdAt }).first {
                        navigationPath.append(latestContent)
                    }
                }
            }
            
            .navigationDestination(for: Content.self) { content in
                ContentDetailView(
                    navigationPath: $navigationPath,
                    content: content
                )
            }
            
            .alert("Rename Content", isPresented: $showRenameContentDialog) {
                TextField("Content Name", text: $newContentName)
                Button("Cancel", role: .cancel) {
                    selectedContent = nil
                    newContentName = ""
                }
                Button("Rename") {
                    renameContent()
                }
            } message: {
                Text("Enter a new name for this content.")
            }
            
            .alert("Delete Content", isPresented: $showDeleteContentConfirmation) {
                Button("Cancel", role: .cancel) {
                    selectedContent = nil
                }
                Button("Delete", role: .destructive) {
                    deleteContent()
                }
            } message: {
                Text("Are you sure you want to delete this content? This action cannot be undone.")
            }
            
            .alert("New Folder", isPresented: $showAddFolderDialog) {
                TextField("Folder Name", text: $newFolderName)
                Button("Cancel", role: .cancel) {
                    newFolderName = ""
                    selectedContent = nil
                }
                Button("Create") {
                    if !newFolderName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        let folder = Folder(name: newFolderName.trimmingCharacters(in: .whitespacesAndNewlines))
                        modelContext.insert(folder)
                        
                        if let content = selectedContent {
                            moveContent(content, to: folder)
                        }
                        
                        newFolderName = ""
                        selectedContent = nil
                    }
                }
            } message: {
                Text("Enter a name for the new folder.")
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter.string(from: date)
    }
    
    private func moveContent(_ content: Content, to folder: Folder?) {
        content.folder = folder
        
        content.lastUpdatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error moving content: \(error.localizedDescription)")
        }
    }
    
    private func renameContent() {
        guard let content = selectedContent, !newContentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        content.title = newContentName.trimmingCharacters(in: .whitespacesAndNewlines)
        content.lastUpdatedAt = Date()
        
        do {
            try modelContext.save()
        } catch {
            print("Error renaming content: \(error.localizedDescription)")
        }
        
        selectedContent = nil
        newContentName = ""
    }
    
    private func deleteContent() {
        guard let content = selectedContent else { return }
        
        modelContext.delete(content)
        
        do {
            try modelContext.save()
        } catch {
            print("Error deleting content: \(error.localizedDescription)")
        }
        
        selectedContent = nil
    }
}

#Preview {
    DashboardView()
}
