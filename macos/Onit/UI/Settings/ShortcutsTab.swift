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

    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder(
                    "Launch Onit", name: .launch
                ) { _ in
                    resetPrompt()
                }
                .padding()

                KeyboardShortcuts.Recorder(
                    "Launch Onit - Incognito", name: .launchIncognito
                ) { _ in
                    resetPrompt()
                }
                .padding()
            }
        }
        .padding()
    }

    func resetPrompt() {
        let view = StaticPromptView().environment(model)
        Accessibility.resetPrompt(with: view)
    }
}

#Preview {
    ShortcutsTab()
}
