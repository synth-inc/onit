//
//  SettingsSidekickDatabase.swift
//  Onit
//
//  Created by Kévin Naudin on 12/04/2025.
//

import SwiftData
import SwiftUI

struct SettingsSidekickDatabase: View {
    // MARK: - States

    @State private var storageInfo: StorageInfo?
    @State private var refreshTrigger = false

    // MARK: - Body

    var body: some View {
        Group {
            if let storageInfo = storageInfo {
                storageStatusCard(storageInfo)

                migrationStatusCard(storageInfo)

                if storageInfo.legacyExists {
                    legacyWarningCard(storageInfo)
                }
            } else {
                ProgressView(String.localized("Loading storage information...", table: "Sidekick"))
                    .frame(height: 100)
            }
        }
        .onAppear {
            loadStorageInfo()
        }
        .onChange(of: refreshTrigger) { _, _ in
            loadStorageInfo()
        }
    }

    // MARK: - Child Components: Storage Status Card

    private func storageStatusCard(_ info: StorageInfo) -> some View {
        SettingsPageSection(title: .init(text: String.localized("Storage Location", table: "Sidekick"))) {
            SettingsPageSubsection(
                vertical: .init(
                    spacing: 8
                ),
                header: .init(
                    title: String.localized("Current Database:", table: "Sidekick")
                )
            ) {
                Text(info.secureLocation?.path ?? "")
                    .styleText(size: 12)
                    .textSelection(.enabled)
                    .padding(8)
                    .background(Color.T_8)
                    .cornerRadius(4)

                HStack(spacing: 6) {
                    Circle()
                        .fill(info.secureExists ? Color.lime400 : Color.orange500)
                        .frame(
                            width: 8,
                            height: 8
                        )

                    Text(info.secureExists ? String.localized("Database exists", table: "Sidekick") : String.localized("Database not found", table: "Sidekick"))
                        .styleText(
                            size: 12,
                            color: Color.S_1
                        )
                }
            }
        }
    }
    
    // MARK: - Child Components: Migration Status Card

    private func migrationStatusCard(_ info: StorageInfo) -> some View {
        SettingsPageSection(title: .init(text: String.localized("Migration Status", table: "Sidekick"))) {
            SettingsPageSubsection {
                Text(migrationStatusText(info))
                    .styleText(
                        size: 12,
                        color: Color.S_2
                    )
            }
        }
    }
    
    // MARK: - Child Components: Legacy Warning Card

    private func legacyWarningCard(_ info: StorageInfo) -> some View {
        SettingsPageSection(title: .init(text: String.localized("Legacy Database Found", table: "Sidekick"))) {
            SettingsPageSubsection(
                vertical: .init(
                    spacing: 8
                ),
                header: .init(
                    title: String.localized("A legacy database file was found at the old location. If migration was successful, you can safely delete the backup file.", table: "Sidekick")
                )
            ) {
                Text(info.legacyLocation?.appendingPathExtension("backup").path ?? "")
                    .styleText(size: 12)
                    .textSelection(.enabled)
                    .padding(8)
                    .background(Color.T_8)
                    .cornerRadius(4)
                
                Button {
                    refreshTrigger.toggle()
                } label: {
                    Text(String.localized("Refresh Status", table: "Sidekick"))
                        .styleText(
                            size: 12,
                            weight: .regular,
                            color: Color.blue
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }

    // MARK: - Private Functions

    private func migrationStatusText(_ info: StorageInfo) -> String {
        if info.migrationCompleted {
            return "✅  " + String.localized("Migration completed successfully. Your data is now stored in a secure, sandboxed location.", table: "Sidekick")
        } else if info.legacyExists && info.secureExists {
            return "⚠️  " + String.localized("Both legacy and secure databases exist. Migration may be in progress or failed.", table: "Sidekick")
        } else if info.legacyExists && !info.secureExists {
            return "📦  " + String.localized("Legacy database found. Migration will occur on next app restart.", table: "Sidekick")
        } else {
            return "🆕  " + String.localized("No legacy data found. Using secure storage from the start.", table: "Sidekick")
        }
    }

    private func loadStorageInfo() {
        Task { @MainActor in
            storageInfo = DatabaseMigrationService.shared.storageInfo
        }
    }
}
