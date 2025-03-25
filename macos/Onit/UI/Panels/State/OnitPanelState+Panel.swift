//
//  OnitPanelState+Panel.swift
//  Onit
//
//  Created by Kévin Naudin on 01/04/2025.
//

import Defaults
import SwiftUI

extension OnitPanelState: NSWindowDelegate {
    
    @MainActor
        func showPanel() {
            if let existingPanel = panel, existingPanel.isVisible {
                existingPanel.makeKeyAndOrderFront(nil)
                existingPanel.orderFrontRegardless()
                // Focus the text input when we're activating the panel
                textFocusTrigger.toggle()
                isPanelOpened.send(true)
                
                return
            }

            // Create a new chat when creating a new panel if the setting is enabled
            // But we don't want to clear out the context, so that autocontext still works.
            if Defaults[.createNewChatOnPanelOpen] {
                newChat(clearContext: false)
            }

            let newPanel: OnitPanel = Defaults[.isRegularApp] ?
                OnitRegularPanel(state: self) :
                OnitAccessoryPanel(state: self)
            
            panel = newPanel
            isPanelOpened.send(true)

            KeyboardShortcutsManager.enable(modelContainer: container)

            // Focus the text input when we're activating the panel
            textFocusTrigger.toggle()
        }

        func closePanel() {
            guard let panel = panel else { return }
            
            SystemPromptState.shared.shouldShowSelection = false
            SystemPromptState.shared.shouldShowSystemPrompt = false

            if !Defaults[.isRegularApp] {
                panel.hide()
                self.panel = nil
            }
            
            isPanelOpened.send(false)
            
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
                textFocusTrigger.toggle()
            }
        }

        func escapeAction() {
            if panel != nil {
                if pendingInput != nil {
                    pendingInput = nil
                } else {
                    closePanel()
                }
            }
        }
        
        // MARK: - NSWindowDelegate

        func windowDidResignKey(_ notification: Notification) {
            //        closePanel()
        }
        
        func windowWillMiniaturize(_ notification: Notification) {
            isPanelMiniaturized.send(true)
        }
        
        func windowDidDeminiaturize(_ notification: Notification) {
            isPanelMiniaturized.send(false)
        }
        
        func windowShouldClose(_ sender: NSWindow) -> Bool {
            closePanel()
            
            return !Defaults[.isRegularApp]
        }
}
