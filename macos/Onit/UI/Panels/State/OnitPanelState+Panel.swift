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

        if Defaults[.isRegularApp] {
            if trackedWindow != nil {
                repositionPanel()
            } else {
                print("Something went wrong while trying to reposition the panel.")
            }
        }

        KeyboardShortcutsManager.enable(modelContainer: container)

        // Focus the text input when we're activating the panel
        textFocusTrigger.toggle()
    }

    func closePanel() {
        guard let panel = panel else { return }
        
        systemPromptState.shouldShowSelection = false
        systemPromptState.shouldShowSystemPrompt = false

        if Defaults[.isRegularApp] {
            if trackedWindow != nil {
                restoreWindowPosition()
            } else {
                // What to do
            }
        } else {
            panel.hide()
            self.panel = nil
        }
        
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
    
    func handlePanelClicked() {
        textFocusTrigger.toggle()
        foregroundTrackedWindowIfNeeded()
    }
    
    private func foregroundTrackedWindowIfNeeded() {
        guard let panel = panel, panel.level != .floating,
              let window = trackedWindow?.element else { return }
        
        window.bringToFront()
        
        notifyDelegates { delegate in
            delegate.panelStateDidChange(state: self)
        }
    }
        
    // MARK: - NSWindowDelegate
    
    func windowDidBecomeKey(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, panel == window else { return }
        
        foregroundTrackedWindowIfNeeded()
    }

    func windowDidResignKey(_ notification: Notification) {
        //        closePanel()
    }

    func windowWillMiniaturize(_ notification: Notification) {
        if !panelMiniaturized {
            panelMiniaturized = true
        }
    }
    
    func windowDidDeminiaturize(_ notification: Notification) {
        if panelMiniaturized {
            panelMiniaturized = false
        }
    }
    
    func windowShouldClose(_ sender: NSWindow) -> Bool {
        closePanel()
        
        return !Defaults[.isRegularApp]
    }
}
