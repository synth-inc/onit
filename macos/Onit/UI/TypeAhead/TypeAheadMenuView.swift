//
//  TypeAheadMenuView.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//

import Defaults
import KeyboardShortcuts
import SwiftUI

struct TypeAheadMenuView: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    @Default(.typeaheadConfig) var typeaheadConfig
    
    private let globalState = TypeAheadState.shared
    private let moreSuggestionsState = TypeAheadMoreSuggestionsState.shared
    
    private var appName: String? {
        AccessibilityNotificationsManager.shared.screenResult.applicationName
    }
    private var shortcut: KeyboardShortcut? {
        KeyboardShortcuts.getShortcut(for: .showTypeAheadMenu)?.native
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            
            TypeAheadMenuRowView(text: "More suggestions", image: .joystick, action: moreSuggestionsAction)
            TypeAheadMenuRowView(text: "View context", image: .paperclip, action: viewContextAction)
            //TypeAheadMenuRowView(text: "Reject", image: .escape, action: rejectAction)
            
            Divider()
                .padding(.horizontal, -8)
            TypeAheadMenuRowView(text: "Pause for 1h", image: .clockSnooze, action: pauseForOneHourAction)
            if let appName = appName {
                TypeAheadMenuRowView(text: "Turn off for \(appName)", image: .circleMinus, action: excludeAppAction)
            }
            Divider()
                .padding(.horizontal, -8)
            TypeAheadMenuRowView(text: "Advanced settings", image: .settingsCog, action: advancedSettingsAction)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.typeAheadMenuBG)
                .stroke(.gray500)
        }
    }
    
    private var header: some View {
        HStack {
            Text("Onit Typeahead")
                .foregroundStyle(.gray100)
            Spacer()
            KeyboardShortcutView(shortcut: shortcut, characterWidth: 12, spacing: 3)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(.gray200)
        }
        .padding(8)
        .appFont(.medium13)
    }
    
    private func moreSuggestionsAction() {
        Task {
            await moreSuggestionsState.getMoreSuggestions()
        }
        globalState.showMenu = false
    }
    
    private func viewContextAction() {
        let manager = AccessibilityNotificationsManager.shared
        guard let trackedScreen = manager.windowsManager.activeTrackedWindow else { return }
        
        let screenResult = manager.screenResult
        let autocontext = AutoContext(appName: screenResult.applicationName ?? "",
                                      appHash: trackedScreen.hash,
                                      appTitle: screenResult.applicationTitle ?? "",
                                      appContent: screenResult.others ?? [:])
        let item = Context.auto(autocontext)
        
        ContextWindowsManager.shared.showContextWindow(
            context: item,
            pendingContextList: [] // We cannot access the panelState
        )
        globalState.showMenu = false
    }
    
    private func rejectAction() {
        globalState.showMenu = false
    }
    
    private func pauseForOneHourAction() {
        typeaheadConfig.resumeAt = .now.addingTimeInterval(3600)
        globalState.showMenu = false
    }
    
    private func excludeAppAction() {
        guard let appName = appName else { return }
        
        typeaheadConfig.excludedApps.insert(appName)
        globalState.showMenu = false
    }
    
    private func advancedSettingsAction() {
        appState.setSettingsTab(tab: .typeahead)
        openSettings()
        globalState.showMenu = false
    }
}

#Preview {
    TypeAheadMenuView()
}
