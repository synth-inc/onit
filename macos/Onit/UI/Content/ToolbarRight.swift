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
    
    @Default(.modeToggleShortcutDisabled) var modeToggleShortcutDisabled
    @Default(.footerNotifications) var footerNotifications
    
    var mode: InferenceMode

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            discord
            localMode
            history
            settings
            
            if footerNotifications.contains(.update) {
                installUpdate
            }
        }
        .padding(.trailing, 6)
        .padding(.horizontal, 0)
        .background { escListener }
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
            tooltipPrompt: "Local Mode",
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
            tooltipPrompt: "Join Discord"
        ) {
            MenuJoinDiscord.openDiscord(appState)
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
            tooltipPrompt: "History"
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
            inactiveColor: Color.blue300,
            hoverBackground: Color.blue300.opacity(0.2),
            tooltipPrompt: "Install Update"
        ) {
            appState.checkForAvailableUpdateWithDownload()
        }
    }
}

#Preview {
    ToolbarRight(mode: .remote)
}
