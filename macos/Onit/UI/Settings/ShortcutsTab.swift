//
//  ShortcutsTab.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import KeyboardShortcuts
import SwiftUI

struct ShortcutsTab: View {
    @Environment(\.model) var model

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
