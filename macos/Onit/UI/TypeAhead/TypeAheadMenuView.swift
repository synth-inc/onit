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
    @Environment(\.model) var model
    @Environment(\.openSettings) var openSettings
    @Default(.typeAheadConfig) var typeAheadConfig
    
    private var appName: String? {
        AccessibilityNotificationsManager.shared.screenResult.applicationName
    }
    private var shortcut: KeyboardShortcut? {
        KeyboardShortcuts.getShortcut(for: .launch)?.native
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            header
            
            TypeAheadMenuRowView(text: "More suggestions", image: .joystick, action: moreSuggestionsAction)
            TypeAheadMenuRowView(text: "View context", image: .paperclip, action: viewContextAction)
            TypeAheadMenuRowView(text: "Pause for 1h", image: .clockSnooze, action: pauseForOneHourAction)
            if let appName = appName {
                TypeAheadMenuRowView(text: "Turn off for \(appName)", image: .smallRemove, action: excludeAppAction)
            }
            TypeAheadMenuRowView(text: "Advanced settings", image: .settingsCog, action: advancedSettingsAction)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(rgba: 0x16171AF2))
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
        // TODO: KNA
    }
    
    private func viewContextAction() {
        // TODO: KNA
    }
    
    private func pauseForOneHourAction() {
        typeAheadConfig.resumeAt = .now.addingTimeInterval(3600)
    }
    
    private func excludeAppAction() {
        guard let appName = appName else { return }
        
        typeAheadConfig.excludedApps.insert(appName)
    }
    
    private func advancedSettingsAction() {
        model.setSettingsTab(tab: .accessibility)
        openSettings()
    }
}

#Preview {
    TypeAheadMenuView()
}
