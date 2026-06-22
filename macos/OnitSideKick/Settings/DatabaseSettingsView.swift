//
//  DatabaseSettingsView.swift
//  Onit
//
//  Created by Claude on $(date)
//

import SwiftUI
import SwiftData

struct DatabaseSettingsView: View {
    @State private var storageInfo: StorageInfo?
    @State private var refreshTrigger = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String.localized("Database Storage", table: "Sidekick"))
                .font(.title2)
                .fontWeight(.semibold)
            
            if let storageInfo = storageInfo {
                VStack(alignment: .leading, spacing: 12) {
                    storageStatusCard(storageInfo)
                    migrationStatusCard(storageInfo)
                    
                    if storageInfo.legacyExists {
                        legacyWarningCard(storageInfo)
                    }
                }
            } else {
                ProgressView(String.localized("Loading storage information...", table: "Sidekick"))
                    .frame(height: 100)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            loadStorageInfo()
        }
        .onChange(of: refreshTrigger) { _, _ in
            loadStorageInfo()
        }
    }
    
    private func storageStatusCard(_ info: StorageInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "database")
                    .foregroundColor(Color.blue)
                Text(String.localized("Storage Location", table: "Sidekick"))
                    .font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(String.localized("Current Database:", table: "Sidekick"))
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                    Spacer()
                }
                
                Text(info.secureLocation?.path ?? "")
                    .font(.caption)
                    .textSelection(.enabled)
                    .padding(8)
                    .background(Color.T_8)
                    .cornerRadius(4)
                
                HStack {
                    Circle()
                        .fill(info.secureExists ? Color.green : Color.orange500)
                        .frame(width: 8, height: 8)
                    Text(info.secureExists ? String.localized("Database exists", table: "Sidekick") : String.localized("Database not found", table: "Sidekick"))
                        .font(.caption)
                        .foregroundColor(Color.secondary)
                }
            }
        }
        .padding()
        .addBorder(cornerRadius: 8)
    }
    
    private func migrationStatusCard(_ info: StorageInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: info.migrationCompleted ? "checkmark.shield" : "clock")
                    .foregroundColor(info.migrationCompleted ? Color.green : Color.orange500)
                Text(String.localized("Migration Status", table: "Sidekick"))
                    .font(.headline)
            }
            
            Text(migrationStatusText(info))
                .font(.caption)
                .foregroundColor(Color.secondary)
        }
        .padding()
        .addBorder(cornerRadius: 8)
    }
    
    private func legacyWarningCard(_ info: StorageInfo) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(Color.yellow)
                Text(String.localized("Legacy Database Found", table: "Sidekick"))
                    .font(.headline)
            }
            
            Text(String.localized("A legacy database file was found at the old location. If migration was successful, you can safely delete the backup file.", table: "Sidekick"))
                .font(.caption)
                .foregroundColor(Color.secondary)
            
            Text(info.legacyLocation?.appendingPathExtension("backup").path ?? "")
                .font(.caption)
                .textSelection(.enabled)
                .padding(8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(4)
            
            Button(String.localized("Refresh Status", table: "Sidekick")) {
                refreshTrigger.toggle()
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .addBorder(cornerRadius: 8)
    }
    
    private func migrationStatusText(_ info: StorageInfo) -> String {
        if info.migrationCompleted {
            return "✅ " + String.localized("Migration completed successfully. Your data is now stored in a secure, sandboxed location.", table: "Sidekick")
        } else if info.legacyExists && info.secureExists {
            return "⚠️ " + String.localized("Both legacy and secure databases exist. Migration may be in progress or failed.", table: "Sidekick")
        } else if info.legacyExists && !info.secureExists {
            return "📦 " + String.localized("Legacy database found. Migration will occur on next app restart.", table: "Sidekick")
        } else {
            return "🆕 " + String.localized("No legacy data found. Using secure storage from the start.", table: "Sidekick")
        }
    }
    
    private func loadStorageInfo() {
        Task { @MainActor in
            storageInfo = DatabaseMigrationService.shared.storageInfo
        }
    }
}

#Preview {
    DatabaseSettingsView()
        .frame(width: 500, height: 400)
} 
