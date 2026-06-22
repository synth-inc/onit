//
//  ToolbarRight.swift
//  Onit
//
//  Created by Benjamin Sage on 9/20/24.
//

import Defaults
import KeyboardShortcuts
import SwiftUI

struct ToolbarRight: View {
    @Environment(\.appState) private var appState
    @Environment(\.windowState) private var state
    
    @Default(.modeToggleShortcutDisabled) var modeToggleShortcutDisabled
    @Default(.footerNotifications) var footerNotifications
    @Default(.memoriesEnabled) var memoriesEnabled

    @State private var showMemoriesPopover: Bool = false
    @State private var showAddMemorySheet: Bool = false
    @State private var newMemoryContent: String = ""
    
    var mode: InferenceMode

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            discord
            localMode
            history
            if memoriesEnabled {
                memories
            }
            settings
            
            if footerNotifications.contains(.update) {
                installUpdate
            }
        }
        .padding(.trailing, 6)
        .padding(.horizontal, 0)
        .background { escListener }
        .sheet(isPresented: $showAddMemorySheet) {
            AddMemorySheet(content: $newMemoryContent) { memory in
                Task {
                    do {
                        try await MemoryManager.shared.create(memory)
                        newMemoryContent = ""
                        showAddMemorySheet = false
                    } catch {
                        log.error("[ToolbarRight] Failed to save memory: \(error)")
                    }
                }
            }
        }
    }

    // Empty view for layout purposes
    var escListener: some View {
        EmptyView()
    }

    func toggleMode() {
        if !modeToggleShortcutDisabled {
            let oldMode = mode
            
            Defaults[.mode] = mode == .local ? .remote : .local
            
            AnalyticsManager.Toolbar.llmModeToggled(oldValue: oldMode, newValue: mode)
        }
    }
    
    var localMode: some View {
        IconButton(
            icon: mode == .local ? .localModeActive : .localMode,
            iconSize: 22,
            isActive: mode == .local,
            activeColor: Color.lime400,
            activeBackground: Color.clear,
            activeBorderColor: Color.clear,
            tooltipPrompt: String.localized("Local Mode", table: "Sidekick"),
            tooltipShortcut: .keyboardShortcuts(.toggleLocalMode)
        ) {
            toggleMode()
        }
        .disabled(modeToggleShortcutDisabled)
        .allowsHitTesting(!modeToggleShortcutDisabled)
    }

    var discord: some View {
        IconButton(
            icon: .logoDiscord,
            iconSize: 21,
            tooltipPrompt: String.localized("Join Discord", table: "Sidekick")
        ) {
            MenuBarDiscord.openDiscord()
        }
    }
   
    var showHistory: Bool { state?.showHistory ?? false }
    
    var showHistoryBinding: Binding<Bool> {
        Binding(
            get: { self.showHistory },
            set: { self.state?.showHistory = $0 }
        )
    }
    
    var history: some View {
        IconButton(
            icon: .history,
            iconSize: 22,
            isActive: state?.showHistory ?? false,
            tooltipPrompt: String.localized("History", table: "Sidekick")
        ) {
            AnalyticsManager.Toolbar.historyPressed(displayed: state?.showHistory ?? false)
            state?.showHistory.toggle()
        }
        .popover(
            isPresented: showHistoryBinding,
            arrowEdge: .bottom
        ) {
            if let state = state {
                HistoryView()
                    .modelContainer(state.container)
            }
        }
    }

    var memories: some View {
        IconButton(
            systemName: "brain",
            iconSize: 18,
            isActive: showMemoriesPopover,
            tooltipPrompt: "Memories"
        ) {
            showMemoriesPopover.toggle()
        }
        .popover(
            isPresented: $showMemoriesPopover,
            arrowEdge: .bottom
        ) {
            MemoriesQuickView {
                // Delay sheet presentation to allow popover to dismiss
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showAddMemorySheet = true
                }
            }
        }
    }

    func openSettingsWindow() {
        AnalyticsManager.Toolbar.settingsPressed()
        SettingsWindowManager.shared.showWindow(page: .panelBehavior)
    }
    var settings: some View {
        IconButton(
            icon: .settingsCog,
            iconSize: 22,
            tooltipPrompt: String.localized("Settings", table: "Sidekick")
        ) {
            openSettingsWindow()
        }
    }

    var installUpdate: some View {
        IconButton(
            icon: .lightning,
            iconSize: 21,
            inactiveColor: Color.blue300,
            hoverBackground: Color.blue300.opacity(0.2),
            tooltipPrompt: String.localized("Install Update", table: "Sidekick")
        ) {
            appState.checkForAvailableUpdateWithDownload()
        }
    }
}

#Preview {
    ToolbarRight(mode: .remote)
}
