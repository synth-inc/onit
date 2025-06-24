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
    @Default(.footerNotifications) var footerNotifications

    var body: some View {
        HStack(alignment: .center, spacing: 4) {
            discord
            localMode
            history
            settings
            
            if footerNotifications.contains(.update) {
                installUpdate
            }
        }
        .padding(.trailing, 6)
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
            isActive: mode == .local,
            activeColor: .limeGreen,
            activeBackground: .clear,
            activeBorderColor: .clear,
            tooltipPrompt: "Local Mode",
            tooltipShortcut: .keyboardShortcuts(.toggleLocalMode),
        ) {
            toggleMode()
        }
    }

    var discord: some View {
        IconButton(
            icon: .logoDiscord,
            iconSize: 21,
            tooltipPrompt: "Join Discord"
        ) {
            MenuJoinDiscord.openDiscord(appState)
        }
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
            isActive: state.showHistory,
            tooltipPrompt: "History"
        ) {
            AnalyticsManager.Toolbar.historyPressed(displayed: state.showHistory)
            state.showHistory.toggle()
        }
        .popover(
            isPresented: showHistoryBinding,
            arrowEdge: .bottom
        ) {
            HistoryView()
                .modelContainer(state.container)
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
            tooltipPrompt: "Settings"
        ) {
            openSettingsWindow()
        }
    }
    
    var installUpdate: some View {
        IconButton(
            icon: .lightning,
            iconSize: 21,
            inactiveColor: .blue300,
            hoverBackground: .blue300.opacity(0.2),
            tooltipPrompt: "Install Update"
        ) {
            appState.checkForAvailableUpdateWithDownload()
        }
    }
}

#Preview {
    ToolbarRight()
}
