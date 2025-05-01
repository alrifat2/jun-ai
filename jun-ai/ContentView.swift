//
//  ContentView.swift
//  jun-ai
//
//  Created by Al Rifat on 4/24/25.
//

import SwiftUI
import SwiftData

enum SidebarItem: Hashable {
    case dashboard
    case settings
    case folder(Folder)
}

struct ContentView: View {
    @State private var selection: SidebarItem? = .dashboard
    @Environment(\.modelContext) private var modelContext
    @Query private var folders: [Folder]
    
    @State private var showAddFolderDialog = false
    @State private var newFolderName = ""
    @State private var showContextMenu = false
    @State private var selectedFolder: Folder?
    @State private var showRenameDialog = false
    @State private var showDeleteConfirmation = false
    
    private var viewModel: DashboardViewModel {
        DashboardViewModel(modelContext: modelContext)
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 0) {
                List(selection: $selection) {
                    Section {
                        NavigationLink(value: SidebarItem.dashboard) {
                            Label("Dashboard", systemImage: "rectangle.grid.2x2")
                        }
                        
                        NavigationLink(value: SidebarItem.settings) {
                            Label("Settings", systemImage: "gearshape")
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Folders")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showAddFolderDialog = true
                                newFolderName = ""
                            } label: {
                                Image(systemName: "plus")
                                    .font(.subheadline)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        
                        ForEach(folders) { folder in
                            NavigationLink(value: SidebarItem.folder(folder)) {
                                Label(folder.name, systemImage: "folder")
                            }
                            .contextMenu {
                                Button("Rename") {
                                    selectedFolder = folder
                                    newFolderName = folder.name
                                    showRenameDialog = true
                                }
                                
                                Divider()
                                
                                Button("Delete", role: .destructive) {
                                    selectedFolder = folder
                                    showDeleteConfirmation = true
                                }
                            }
                        }
                    }
                }
                .listStyle(SidebarListStyle())
                .frame(maxHeight: .infinity)

                HStack {
                    Text("v1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Link("GitHub", destination: URL(string: "https://github.com/your-repo")!)
                        .font(.caption)
                    Link("X.com", destination: URL(string: "https://github.com/your-repo")!)
                        .font(.caption)
                }
                .padding(.horizontal)
                .padding(.bottom, 12)
            }
            .frame(minWidth: 220)
            .navigationTitle("jun-ai")
        } detail: {
            switch selection {
            case .dashboard:
                DashboardView()
            case .settings:
                SettingView()
            case .folder(let folder):
                FolderView(folder: folder)
            default:
                Text("Select an option")
                    .foregroundStyle(.secondary)
            }
        }
        .alert("New Folder", isPresented: $showAddFolderDialog) {
            TextField("Folder Name", text: $newFolderName)
            
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                viewModel.createFolder(folderName: newFolderName)
            }
        } message: {
            Text("Enter a name for the new folder")
        }
        .alert("Rename Folder", isPresented: $showRenameDialog) {
            TextField("Folder Name", text: $newFolderName)
            
            Button("Cancel", role: .cancel) {}
            Button("Rename") {
                viewModel.renameFolder(folder: selectedFolder, newName: newFolderName)
            }
        } message: {
            Text("Enter a new name for the folder")
        }
        .alert("Delete Folder", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                showDeleteConfirmation = false
                selectedFolder = nil
            }
            
            Button("Delete", role: .destructive) {
                if let folder = selectedFolder {
                    viewModel.deleteFolder(folder: folder)
                }
                selectedFolder = nil
                showDeleteConfirmation = false
            }
        } message: {
            Text("All content inside the folder will be deleted")
        }
    }
}


