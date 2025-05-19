//
//  OnitPanelState+Panel.swift
//  Onit
//
//  Created by Kévin Naudin on 01/04/2025.
//

import Defaults
import SwiftUI
import PostHog

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

        panel = OnitRegularPanel(state: self)

        if trackedWindow != nil {
            repositionPanel(action: .undefined)
        } else if trackedScreen != nil {
            showPanelForScreen()
        } else {
            print("Something went wrong while trying to reposition the panel.")
        }

        // Focus the text input when we're activating the panel
        textFocusTrigger.toggle()
    }

    func closePanel() {
        guard let panel = panel else { return }
        
        systemPromptState.shouldShowSelection = false
        systemPromptState.shouldShowSystemPrompt = false

        restoreWindowPosition()
    }
    
    func launchPanel() {
        guard let panel = panel else {
            PostHogSDK.shared.capture("launch_panel", properties:  ["applicationName": trackedWindow?.element.appName() ?? "N/A"])
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
        
        notifyDelegates { $0.panelBecomeKey(state: self) }
    }

    // MARK: - NSWindowDelegate
    
    func windowDidBecomeKey(_ notification: Notification) {
        notifyDelegates { $0.panelBecomeKey(state: self) }
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
        
        return false
    }
}
