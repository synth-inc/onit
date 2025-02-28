//
//  ShortcutsTab.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import KeyboardShortcuts
import SwiftUI
import Defaults

struct ShortcutsTab: View {
    @Environment(\.model) var model

    @Default(.escapeShortcutDisabled) var escapeShortcutDisabled

    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    private var accessibilityAutoContextEnabled: Bool {
        featureFlagsManager.accessibilityAutoContext
    }

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder(
                    "Launch Onit", name: .launch
                ) {
                    resetPrompt(empty: $0 == nil)
                }
                .padding()

                if accessibilityAutoContextEnabled {
                    KeyboardShortcuts.Recorder(
                        "Launch Onit with Auto-Context", name: .launchWithAutoContext
                    )
                    .padding()
                }

                KeyboardShortcuts.Recorder(
                    "New Chat", name: .newChat
                )
                .padding()

                KeyboardShortcuts.Recorder(
                    "Resize Window", name: .resizeWindow
                )
                .padding()

                KeyboardShortcuts.Recorder(
                    "Switch Local vs Remote", name: .toggleLocalMode
                )
                .padding()
                
                Toggle("Disable 'ESC' shortcut", isOn: $escapeShortcutDisabled)
                .padding()
            }
        }
        .onChange(of: escapeShortcutDisabled) { newValue in
            if newValue {
                // True is disabled. 
                KeyboardShortcuts.disable(.escape)
            } else {
                KeyboardShortcuts.enable(.escape)
                
            }
        }
        .padding()
    }

    func resetPrompt(empty: Bool) {
        //let view = StaticPromptView().environment(model)
        HighlightHintWindowController.shared.shortcutChanges(empty: empty)
    }
}

#Preview {
    ShortcutsTab()
}
