//
//  Model+Panel.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import Defaults
import SwiftUI

extension OnitModel: NSWindowDelegate {
    @MainActor
    func showPanel() {
        if let existingPanel = panel, existingPanel.isVisible {
            existingPanel.makeKeyAndOrderFront(nil)
            existingPanel.orderFrontRegardless()
            // Focus the text input when we're activating the panel
            self.textFocusTrigger.toggle()
            return
        }

        // Create a new chat when creating a new panel if the setting is enabled
        // But we don't want to clear out the context, so that autocontext still works.
        if Defaults[.createNewChatOnPanelOpen] {
            newChat(clearContext: false)
        }

        let newPanel: OnitPanel = Defaults[.isRegularApp] ?
            OnitRegularPanel(model: self) :
            OnitAccessoryPanel(model: self)
        
        panel = newPanel

        KeyboardShortcutsManager.enable(modelContainer: container)

        // Focus the text input when we're activating the panel
        self.textFocusTrigger.toggle()
    }

    func closePanel() {
        guard let panel = panel else { return }
        
        SystemPromptState.shared.shouldShowSelection = false
        SystemPromptState.shared.shouldShowSystemPrompt = false

        panel.hide()
        self.panel = nil
        
        HighlightHintWindowController.shared.adjustWindow()
        KeyboardShortcutsManager.disable(modelContainer: container)
    }
    
    func launchPanel() {
        guard let panel = panel else {
            showPanel()
            return
        }

        // If we're using the shortcut as a Toggle, dismiss the panel.
        if Defaults[.launchShortcutToggleEnabled] {
            closePanel()
        } else {
            panel.show()
            
            isPanelOpened.send(true)
            self.textFocusTrigger.toggle()
        }
    }

    func escapeAction() {
        if panel != nil {
            if self.pendingInput != nil {
                self.pendingInput = nil
            } else {
                closePanel()
            }
        }
    }
    
    // MARK: - NSWindowDelegate

    func windowDidResignKey(_ notification: Notification) {
        //        closePanel()
    }
    
    func windowDidMiniaturize(_ notification: Notification) {
        isPanelMiniaturized.send(true)
    }
    
    func windowDidDeminiaturize(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.isPanelMiniaturized.send(false)
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        closePanel()
        
        return true
    }
}
