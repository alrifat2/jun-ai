//
//  SettingView.swift
//  jun-ai
//
//  Created by Al Rifat on 4/24/25.
//

import SwiftUI
import SwiftData

struct SettingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [Setting]
    
    @State private var apiKey: String = ""
    @State private var showResetAlert = false
    @State private var saveSuccess = false
    @FocusState private var isAPIKeyFocused: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Settings")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.primary)
                .padding(.bottom, 8)
            
            apiKeySection
            
            Divider()
                .padding(.vertical, 8)
            
            dangerZoneSection
        }
        .padding(20)
        .frame(minWidth: 500, idealWidth: 550, maxWidth: 650)
        .onAppear(perform: loadSettings)
    }
    
    private var apiKeySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("API Configuration")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Google AI Studio API Key")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                
                HStack(spacing: 8) {
                    SecureField("Enter your API key", text: $apiKey)
                        .focused($isAPIKeyFocused)
                        .font(.system(.body, design: .monospaced))
                        .onSubmit(saveApiKey)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.secondary.opacity(isAPIKeyFocused ? 0.4 : 0.2), lineWidth: isAPIKeyFocused ? 1.2 : 0.8)
                                .background(colorScheme == .dark ? Color(.textBackgroundColor) : Color.white)
                        )
                        .frame(height: 32)
                    
                    Button(action: saveApiKey) {
                        Text("Save")
                            .frame(width: 80)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.extraLarge)
                    .frame(height: 32)
                    .keyboardShortcut(.return, modifiers: .command)
                    .disabled(apiKey.isEmpty)
                }
                
                if saveSuccess {
                    Label("API key saved successfully", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.subheadline)
                        .transition(.opacity)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation {
                                    saveSuccess = false
                                }
                            }
                        }
                }
                
                HStack(spacing: 8) {
                    Image(systemName: "lock.fill")
                        .foregroundStyle(.secondary)
                    
                    Text("Your API key is stored securely on this device and is never transmitted to any server other than Google's API endpoints.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color(.controlBackgroundColor) : Color(.controlBackgroundColor).opacity(0.5))
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
    }
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danger Zone")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                        .font(.title3)
                    
                    Text("Reset Application Data")
                        .font(.headline)
                        .foregroundStyle(.red)
                }
                
                Text("This will permanently delete all folders, content entries, and stored settings including your API key. This action cannot be undone. ")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash.fill")
                        Text("Delete All Data")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.large)
                .padding(.top, 8)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(colorScheme == .dark ? Color(.controlBackgroundColor) : Color(.controlBackgroundColor).opacity(0.5))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
            )
        }
        .alert("Reset Database?", isPresented: $showResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive, action: resetDatabase)
        } message: {
            Text("This will permanently delete all data. You cannot undo this action.")
        }
    }
    
    private func loadSettings() {
        if let existing = settings.first {
            apiKey = existing.aiKey
        }
        
        if apiKey.isEmpty {
            isAPIKeyFocused = false
        }
    }
    
    private func saveApiKey() {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        if let existing = settings.first {
            existing.aiKey = apiKey
            existing.createdAt = Date()
        } else {
            let new = Setting(aiKey: apiKey)
            modelContext.insert(new)
        }
        
        do {
            try modelContext.save()
            withAnimation {
                saveSuccess = true
            }
        } catch {
            print("Failed to save API key: \(error)")
        }
    }
    
    private func resetDatabase() {
        do {
            try modelContext.delete(model: Folder.self)
            try modelContext.delete(model: Content.self)
            try modelContext.delete(model: Setting.self)
            
            try modelContext.save()
            apiKey = ""
            
        } catch {
            print("Failed to reset database: \(error)")
        }
    }
}

#Preview {
    SettingView()
        .modelContainer(for: [Setting.self, Folder.self, Content.self], inMemory: true)
}

extension ModelContext {
    func delete<T: PersistentModel>(model: T.Type) throws {
        try delete(FetchDescriptor<T>())
    }
    
    func delete<T: PersistentModel>(_ fetchDescriptor: FetchDescriptor<T>) throws {
        let objects = try fetch(fetchDescriptor)
        for object in objects {
            delete(object)
        }
    }
}
