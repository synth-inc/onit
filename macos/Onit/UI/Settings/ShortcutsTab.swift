//
//  ShortcutsTab.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI
import KeyboardShortcuts

struct ShortcutsTab: View {
    @Environment(\.model) var model
    
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    private var accessibilityAutoContextEnabled: Bool {
        featureFlagsManager.accessibility && featureFlagsManager.accessibilityAutoContext
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
                
                KeyboardShortcuts.Recorder(
                    "Switch Local vs Remote", name: .toggleLocalMode
                )
                .padding()

                KeyboardShortcuts.Recorder(
                    "New Chat", name: .newChat
                )
                .padding()

                KeyboardShortcuts.Recorder(
                    "Resize Window", name: .resizeWindow
                )
                .padding()

                KeyboardShortcuts.Recorder(
                    "Toggle Models", name: .toggleModels
                )
                .padding()

                if accessibilityAutoContextEnabled {
                    KeyboardShortcuts.Recorder(
                        "Add auto-context", name: .addAutoContext
                    )
                    .padding()
                }
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
