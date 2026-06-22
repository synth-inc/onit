//
//  SettingsSidekickShortcuts.swift
//  Onit
//
//  Created by Kévin Naudin on 12/04/2025.
//

import Defaults
import KeyboardShortcuts
import SwiftUI

struct SettingsSidekickShortcuts: View {
    // MARK: - Defaults

    @Default(.autoContextFromCurrentWindow) private var autoContextFromCurrentWindow
    @Default(.escapeShortcutDisabled) private var escapeShortcutDisabled

    // MARK: - Observations

    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared

    // MARK: - Body

    var body: some View {
        SettingsPageSection(title: .init(text: String.localized("Keyboard Shortcuts", table: "Sidekick"))) {
            shortcutRecorder(
                name: .launch,
                label: String.localized("Launch Onit", table: "Sidekick")
            )
            
            DividerHorizontal()
            
            shortcutRecorder(
                name: .toggleLocalMode,
                label: String.localized("Switch Local vs Remote", table: "Sidekick")
            )
            
            DividerHorizontal()
            
            if accessibilityPermissionManager.accessibilityPermissionStatus == .granted && autoContextFromCurrentWindow {
                shortcutRecorder(
                    name: .addForegroundWindowToContext,
                    label: String.localized("Add Current Window to Context", table: "Sidekick")
                )
            }
        }
        
        SettingsPageSection(title: .init(text: String.localized("Options", table: "Sidekick"))) {
            SettingsPageSubsection(
                header: .init(
                    title: String.localized("Disable 'ESC' shortcut", table: "Sidekick"),
                    subtitle: String.localized("When enabled, pressing ESC will not close the Onit panel.", table: "Sidekick")
                ),
                isOn: self.$escapeShortcutDisabled
            )
        }
    }

    // MARK: - Child Components

    private func shortcutRecorder(name: KeyboardShortcuts.Name, label: String) -> some View {
        SettingsPageSubsection(
            header: .init(title: label)
        ) {
            KeyboardShortcuts.Recorder(for: name)
        }
    }
}
