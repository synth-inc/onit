//
//  PanelStateConventionalManager+Delegates.swift
//  Onit
//
//  Created by Codex on 2024-06-01.
//

import AppKit

extension PanelStateConventionalManager: OnitPanelStateDelegate {
    func panelBecomeKey(state: OnitPanelState) {
        self.state = state
        KeyboardShortcutsManager.enable(modelContainer: SwiftDataContainer.appContainer)
    }
    func panelResignKey(state: OnitPanelState) {
        KeyboardShortcutsManager.disable(modelContainer: SwiftDataContainer.appContainer)
    }
    func panelStateDidChange(state: OnitPanelState) {
        if !state.panelOpened {
            activateMouseScreen(forced: true)
        } else {
            state.panel?.setLevel(.floating)
        }
    }
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) { }
}
