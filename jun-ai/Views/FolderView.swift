//
//  FolderView.swift
//  jun-ai
//
//  Created by Al Rifat on 4/27/25.
//

import SwiftUI
import SwiftData

struct FolderView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    
    let folder: Folder
    @State private var navigationPath = NavigationPath()
    @State private var selectedContent: Content?
    @State private var newContentName = ""
    @State private var showRenameContentDialog = false
    @State private var showDeleteContentConfirmation = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Label(folder.name, systemImage: "folder.fill")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.primary)
                    
                    Spacer()
                    
                    Text("\(folder.contents.count) item\(folder.contents.count == 1 ? "" : "s")")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }
                .padding(.top, -4)
                .padding(.bottom, 16)
                
                if folder.contents.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "folder.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundStyle(.secondary)
                        
                        Text("No content in this folder")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text("Right-click content in Dashboard to move it to this folder")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(folder.contents.sorted(by: { $0.lastUpdatedAt > $1.lastUpdatedAt })) { content in
                                Button {
                                    navigationPath.append(content)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(content.title)
                                                .font(.headline)
                                                .foregroundStyle(.primary)
                                            
                                            Text(content.contentType.rawValue.capitalized)
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Text(formatDate(content.lastUpdatedAt))
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
                                    
                                    Button {
                                        moveContent(content, to: nil)
                                    } label: {
                                        Label("Remove from Folder", systemImage: "folder.badge.minus")
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
            .padding(.top, 0)
            .padding([.horizontal, .bottom], 20)
            .frame(minWidth: 500, idealWidth: 800, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            
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
