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
    @Environment(\.openSettings) var openSettings
    @Environment(\.windowState) private var state
    
    @Default(.mode) var mode

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            discord
            localMode
            history
            settings
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 32, alignment: .center)
        .foregroundStyle(.gray200)
        .padding(.horizontal, 0)
        .background { escListener }
    }

    // Empty view for layout purposes
    var escListener: some View {
        EmptyView()
    }

    func toggleMode() {
        let oldMode = mode
        
        mode = mode == .local ? .remote : .local
        
        AnalyticsManager.Toolbar.llmModeToggled(oldValue: oldMode, newValue: mode)
    }
    
    var localMode: some View {
        IconButton(
            icon: mode == .local ? .localModeActive : .localMode,
            iconSize: 22,
            action: { toggleMode() },
            isActive: mode == .local,
            activeColor: .limeGreen,
            tooltipPrompt: "Local Mode",
            tooltipShortcut: .keyboardShortcuts(.toggleLocalMode)
        )
    }

    func openDiscord() {
        if let url = URL(string: MenuJoinDiscord.link) {
            NSWorkspace.shared.open(url)
        }
    }

    var discord: some View {
        IconButton(
            icon: .logoDiscord,
            iconSize: 22,
            action: { openDiscord() },
            tooltipPrompt: "Join Discord"
        )
    }

    var showHistoryBinding: Binding<Bool> {
        Binding(
            get: { self.state.showHistory },
            set: { self.state.showHistory = $0 }
        )
    }
    var history: some View {
        IconButton(
            icon: .history,
            iconSize: 22,
            action: {
                AnalyticsManager.Toolbar.historyPressed(displayed: state.showHistory)
                state.showHistory.toggle()
            },
            isActive: state.showHistory,
            tooltipPrompt: "History"
        )
        .popover(
            isPresented: showHistoryBinding,
            arrowEdge: .bottom
        )  {
            HistoryView()
        }
    }

    func openSettingsWindow() {
        AnalyticsManager.Toolbar.settingsPressed()
        
        NSApp.activate()
        if NSApp.isActive {
            appState.setSettingsTab(tab: .general)
            openSettings()
        }
    }
    var settings: some View {
        IconButton(
            icon: .settingsCog,
            iconSize: 22,
            action: { openSettingsWindow() },
            tooltipPrompt: "Settings"
        )
    }
}

#Preview {
    ToolbarRight()
}
