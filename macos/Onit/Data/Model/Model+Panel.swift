//
//  Model+Panel.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI
import KeyboardShortcuts

extension OnitModel: NSWindowDelegate {
    @MainActor
    func showPanel() {
        #if !targetEnvironment(simulator)
        generationState = .idle
        #endif

        if let existingPanel = panel, existingPanel.isVisible {
            existingPanel.makeKeyAndOrderFront(nil)
            existingPanel.orderFrontRegardless()
            return
        }

        let newPanel = CustomPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 0),
            styleMask: [.resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        newPanel.isOpaque = false
        newPanel.backgroundColor = NSColor.clear
        newPanel.level = .floating
        newPanel.titleVisibility = .hidden
        newPanel.titlebarAppearsTransparent = true
        newPanel.isMovableByWindowBackground = true
        newPanel.delegate = self

        newPanel.standardWindowButton(.closeButton)?.isHidden = true
        newPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        newPanel.standardWindowButton(.zoomButton)?.isHidden = true
        newPanel.isFloatingPanel = true

        let contentView = ContentView()
            .modelContainer(container)
            .environment(self)

        let panelContentView = NSHostingView(rootView: contentView)
        panelContentView.wantsLayer = true
        panelContentView.layer?.cornerRadius = 14
        panelContentView.layer?.cornerCurve = .continuous
        panelContentView.layer?.masksToBounds = true
        panelContentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        newPanel.contentView = panelContentView
        newPanel.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))
        panel = newPanel

        if showDebugWindow {
            let debugPanel = CustomPanel(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 800),
                styleMask: [.resizable, .nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false)
            debugPanel.isOpaque = false
            debugPanel.backgroundColor = NSColor.clear
            debugPanel.level = .floating
            debugPanel.titleVisibility = .hidden
            debugPanel.titlebarAppearsTransparent = true
            debugPanel.isMovableByWindowBackground = true
            debugPanel.delegate = self

            debugPanel.standardWindowButton(.closeButton)?.isHidden = true
            debugPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
            debugPanel.standardWindowButton(.zoomButton)?.isHidden = true
            debugPanel.isFloatingPanel = true
            
            let debugView = DebugView()
                .modelContainer(container)
                .environment(self)
            
            let debugPanelContentView = NSHostingView(rootView: debugView)
            debugPanelContentView.wantsLayer = true
            debugPanelContentView.layer?.cornerRadius = 14
            debugPanelContentView.layer?.cornerCurve = .continuous
            debugPanelContentView.layer?.masksToBounds = true
            debugPanelContentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
            
            debugPanel.contentView = debugPanelContentView
            debugPanel.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))
            self.debugPanel = debugPanel
        }
        
        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame
            let windowWidth = newPanel.frame.width
            let windowHeight = newPanel.frame.height
            
            let finalXPosition = visibleFrame.origin.x + visibleFrame.width - 16 - windowWidth 
            let finalYPosition = visibleFrame.origin.y + visibleFrame.height - 16 - 100

            // Start off-screen to the right
            newPanel.setFrameOrigin(NSPoint(x: finalXPosition, y: finalYPosition))
            newPanel.makeKeyAndOrderFront(nil)
            newPanel.orderFrontRegardless()
            
            if showDebugWindow {
                if let debugPanel = self.debugPanel {
                    debugPanel.setFrameOrigin(NSPoint(x: finalXPosition, y: finalYPosition - (windowHeight * 2.0) - 16))
                    debugPanel.makeKeyAndOrderFront(nil)
                    debugPanel.orderFrontRegardless()
                }
            }
        }

        KeyboardShortcuts.onKeyUp(for: .escape) { [weak self] in
            guard let self else { return }
            self.escapeAction()
        }
        // Focus the text input when we're activating the panel
        textFocusTrigger = true
    }

    func closePanel() {
        KeyboardShortcuts.disable(.escape)
        guard let panel = panel else { return }
        panel.orderOut(nil)
        Accessibility.adjustWindowToTopRight()
        self.panel = nil
    }

    @MainActor
    func togglePanel() {
        if panel != nil {
            closePanel()
        } else {
            showPanel()
        }
    }
    
    func launchPanel() {
        if panel == nil {
            showPanel()
        }
        if let panel = panel {
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
        }
    }
        
    func launchShortcutAction() {
        updatePreferences { prefs in
            prefs.incognito = false
            prefs.mode = .remote
        }
        launchPanel()
    }
    
    func launchIncognitoShortcutAction() {
        updatePreferences { prefs in
            prefs.incognito = true
            prefs.mode = .remote
        }
        launchPanel()
    }
    
    func launchLocalShortcutAction() {
        updatePreferences { prefs in
            prefs.incognito = false
            prefs.mode = .local
        }
        launchPanel()
    }
    
    func launchLocalIncognitoShortcutAction() {
        updatePreferences { prefs in
            prefs.incognito = true
            prefs.mode = .local
        }
        launchPanel()
    }

    func escapeAction() {
        if panel != nil {
            if self.selectedText != "" {
                self.selectedText = ""
                self.sourceText = ""
                self.input = nil
            } else {
                closePanel()
            }
        }
    }
    
    func windowDidResignKey(_ notification: Notification) {
//        closePanel()
    }

    @MainActor
    func adjustPanelSize() {
        guard let panel = panel,
              let contentView = panel.contentView else {
            return
        }
        // Re-measure the SwiftUI hierarchy
        contentView.layoutSubtreeIfNeeded()
        let idealSize = contentView.fittingSize

        // Clamp the window height so it doesn’t fall off-screen
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let maxAllowedHeight = visibleFrame.height - 16
        let newHeight = min(idealSize.height, maxAllowedHeight)
        let currentWidth = panel.frame.width

        // Keep the top edge in place
        let newX = panel.frame.origin.x
        let newY = visibleFrame.origin.y + visibleFrame.height - 16 - newHeight

        // Apply changes
        panel.setFrame(
            NSRect(x: newX, y: newY, width: currentWidth, height: newHeight),
            display: true
        )
    }
}

class CustomPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}
