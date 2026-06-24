//
//  SettingsMemories.swift
//  Onit
//
//  Created by Kévin Naudin on 22/12/2025.
//

import SwiftUI
import AppKit
import Defaults

/// Settings page for managing memories
struct SettingsMemories: View {
    // MARK: - States

    @State private var memories: [Memory] = []
    @State private var showAddSheet: Bool = false
    @State private var newContent: String = ""
    @State private var showAllMemories: Bool = false

    @Default(.memoriesEnabled) var memoriesEnabled
    @Default(.memoryAutoDetectionEnabled) var memoryAutoDetectionEnabled
    @Default(.maxMemoryTokens) var maxMemoryTokens

    private let pageSize = 10

    // MARK: - Body

    var body: some View {
        Group {
            SettingsTitleView(
                text: String.localized("Information that the AI will remember across all conversations.\nMemories are used in SideKick to personalize responses.", table: "Settings")
            )

            SettingsPageSection {
                enableMemoriesToggle
                DividerHorizontal()
                autoDetectToggle
            }
            
            tokenLimitSection
            
            memoriesListSection
        }
        .task {
            await loadMemories()
        }
        .sheet(isPresented: $showAddSheet) {
            AddMemorySheet(content: $newContent) { memory in
                Task {
                    await saveMemory(memory)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var visibleMemories: [Memory] {
        if showAllMemories || memories.count <= pageSize {
            return memories
        }
        return Array(memories.prefix(pageSize))
    }

    private var hasMoreMemories: Bool {
        memories.count > pageSize && !showAllMemories
    }

    private var remainingCount: Int {
        memories.count - pageSize
    }

    // MARK: - Child Components

    private var addMemoryButton: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text(String.localized("Add", table: "Settings"))
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private var enableMemoriesToggle: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Enable memories", table: "Settings"),
                subtitle: String.localized("Include memories in AI prompts to personalize responses.", table: "Settings")
            ),
            isOn: $memoriesEnabled
        )
    }

    private var autoDetectToggle: some View {
        SettingsPageSubsection(
            header: .init(
                title: String.localized("Auto-detect memories", table: "Settings"),
                subtitle: String.localized("Allow AI to suggest saving new memories from conversations.", table: "Settings")
            ),
            isOn: $memoryAutoDetectionEnabled
        )
        .opacity(memoriesEnabled ? 1.0 : 0.5)
        .disabled(!memoriesEnabled)
    }

    private var tokenLimitSection: some View {
        SettingsPageSection {
            SettingsPageSubsection(
                vertical: .init(spacing: 8),
                header: .init(
                    title: String.localized("Token limit", table: "Settings"),
                    subtitle: String.localized("%d tokens", table: "Settings", maxMemoryTokens)
                )
            ) {
                Slider(value: Binding(
                    get: { Double(maxMemoryTokens) },
                    set: { maxMemoryTokens = Int($0) }
                ), in: 100...2000, step: 100)

                Text(String.localized("Maximum tokens of memory context injected per request (~%d characters)", table: "Settings", maxMemoryTokens * 4))
                    .styleText(size: 10, color: Color.T_5)
            }
        }
    }

    private var memoriesListSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Section header with Add button
            HStack {
                Text(String.localized("Saved Memories (%d)", table: "Settings", memories.count))
                    .styleText(size: 13, weight: .semibold)

                Spacer()

                addMemoryButton
            }
            .padding(.horizontal, 16)

            if memories.isEmpty {
                emptyState
            } else {
                VStack(spacing: 8) {
                    ForEach(visibleMemories) { memory in
                        MemorySettingsRow(
                            memory: memory,
                            onToggle: { toggleMemory(memory) },
                            onDelete: { deleteMemory(memory) }
                        )
                    }

                    if hasMoreMemories {
                        showMoreButton
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        SettingsPageSection {
            VStack(alignment: .leading, spacing: 4) {
                Text(String.localized("No memories yet", table: "Settings"))
                    .styleText(size: 12, color: Color.T_4)
                Text(String.localized("Add information you want the AI to remember across conversations.", table: "Settings"))
                    .styleText(size: 11, color: Color.T_5)
            }
        }
    }

    private var showMoreButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showAllMemories = true
            }
        } label: {
            Text(String.localized("Show %d more...", table: "Settings", remainingCount))
                .styleText(size: 12, color: Color.blue)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    // MARK: - Private Functions

    private func loadMemories() async {
        memories = await MemoryManager.shared.fetchAll()
    }

    private func saveMemory(_ memory: Memory) async {
        do {
            try await MemoryManager.shared.create(memory)
            await loadMemories()
            newContent = ""
            showAddSheet = false
        } catch {
            log.error("[SettingsMemories] Failed to save memory: \(error)")
        }
    }

    private func toggleMemory(_ memory: Memory) {
        var updated = memory
        updated.isEnabled.toggle()

        Task {
            do {
                try await MemoryManager.shared.update(updated)
                await loadMemories()
            } catch {
                log.error("[SettingsMemories] Failed to toggle memory: \(error)")
            }
        }
    }

    private func deleteMemory(_ memory: Memory) {
        guard let id = memory.id else { return }

        Task {
            do {
                try await MemoryManager.shared.delete(id: id)
                await loadMemories()
            } catch {
                log.error("[SettingsMemories] Failed to delete memory: \(error)")
            }
        }
    }
}

// MARK: - MemorySettingsRow

/// A row displaying a single memory in the settings list
private struct MemorySettingsRow: View {
    let memory: Memory
    let onToggle: () -> Void
    let onDelete: () -> Void

    private var appIcon: NSImage? {
        guard let bundleId = memory.appBundleIdentifier else { return nil }
        return NSWorkspace.shared.icon(forBundleIdentifier: bundleId)
    }

    private var appName: String {
        if memory.isGlobal {
            return String.localized("All apps", table: "Settings")
        }
        guard let bundleId = memory.appBundleIdentifier else { return "" }
        return NSWorkspace.shared.appName(forBundleIdentifier: bundleId) ?? bundleId
    }

    var body: some View {
        SettingsPageSection {
            HStack(alignment: .center, spacing: 12) {
                // App icon
                if let icon = appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 20, height: 20)
                } else {
                    Image(systemName: "globe")
                        .font(.system(size: 16))
                        .foregroundColor(Color.T_4)
                        .frame(width: 20, height: 20)
                }

                VStack(alignment: .leading, spacing: 4) {
                    // Line 1: App name
                    Text(appName)
                        .styleText(size: 12, weight: .medium)

                    // Line 2: Memory content
                    Text(memory.content)
                        .styleText(size: 11, color: Color.T_4)
                        .lineLimit(2)
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { memory.isEnabled },
                    set: { _ in onToggle() }
                ))
                .toggleStyle(.switch)
                .scaleEffect(0.8)

                Button(action: onDelete) {
                    Image(.circleX)
                        .renderingMode(.template)
                        .foregroundColor(Color.T_4)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
