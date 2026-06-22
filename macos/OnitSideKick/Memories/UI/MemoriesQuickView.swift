//
//  MemoriesQuickView.swift
//  Onit
//
//  Created by Kévin Naudin on 22/12/2025.
//

import SwiftUI

/// Popover accessible from the toolbar button showing a quick view of memories
struct MemoriesQuickView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.windowState) private var windowState

    // MARK: - Properties

    /// Callback when add button is pressed - parent should present the add sheet
    private var onAddMemory: (() -> Void)?

    // MARK: - Init

    init(onAddMemory: (() -> Void)? = nil) {
        self.onAddMemory = onAddMemory
    }

    // MARK: - States

    @State private var scoredMemories: [ScoredMemory] = []

    // MARK: - Computed Properties

    private var currentBundleId: String? {
        (windowState?.trackedWindow ?? windowState?.foregroundWindow)?.pid.bundleIdentifier
    }

    private var selectionContext: MemorySelectionContext {
        let autoContextTexts = windowState?.pendingContextList.autoContexts.values.joined(separator: "\n") ?? ""
        return MemorySelectionContext(
            appBundleIdentifier: currentBundleId,
            userInstruction: windowState?.pendingInstruction ?? "",
            selectedText: windowState?.pendingInput?.selectedText,
            autoContextText: autoContextTexts.isEmpty ? nil : autoContextTexts
        )
    }

    private var activeCount: Int {
        scoredMemories.count
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            DividerHorizontal()

            memoryList
                .padding(.top, 8)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(width: 280)
        .onAppear {
            loadMemoriesSync()
        }
    }

    // MARK: - Child Components

    private var header: some View {
        HStack(spacing: 4) {
            Text("Memories (\(activeCount) active)")
                .styleText(size: 13, weight: .semibold)

            Spacer()

            IconButton(
                icon: .circlePlus,
                iconSize: 20,
                buttonSize: 32,
                tooltipPrompt: "Add a memory"
            ) {
                dismiss()
                onAddMemory?()
            }

            IconButton(
                icon: .settingsCog,
                iconSize: 20,
                buttonSize: 32,
                tooltipPrompt: "Memory Settings"
            ) {
                dismiss()
                SettingsWindowManager.shared.showWindow(page: .memories)
            }
        }
    }

    @ViewBuilder
    private var memoryList: some View {
        if scoredMemories.isEmpty {
            Text("No memories for this app")
                .styleText(size: 12, color: Color.T_4)
                .padding(.vertical, 8)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(scoredMemories.prefix(5)) { scored in
                    MemoryQuickRow(memory: scored.memory)
                }

                if scoredMemories.count > 5 {
                    Text("+ \(scoredMemories.count - 5) more")
                        .styleText(size: 11, color: Color.T_5)
                }
            }
        }
    }

    // MARK: - Private Functions

    private func loadMemoriesSync() {
        Task { @MainActor in
            let allMemories = await MemoryManager.shared.fetchForApp(bundleIdentifier: currentBundleId)
            scoredMemories = MemorySelector.select(memories: allMemories, context: selectionContext)
        }
    }
}

// MARK: - MemoryQuickRow

/// A compact row displaying a single memory in the quick view
private struct MemoryQuickRow: View {
    let memory: Memory
    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            Text("•")
                .styleText(size: 12, color: Color.T_4)

            Text(memory.content)
                .styleText(size: 12)
                .lineLimit(1)

            Spacer()
        }
        .onHover { hovering in
            isHovered = hovering
        }
        .popover(isPresented: $isHovered, arrowEdge: .leading) {
            Text(memory.content)
                .styleText(size: 12)
                .padding(8)
                .frame(maxWidth: 200)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
