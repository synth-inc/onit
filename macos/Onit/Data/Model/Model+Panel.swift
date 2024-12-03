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
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
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
            let finalYPosition = visibleFrame.origin.y + visibleFrame.height - 16 - windowHeight

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

    func keyboardShortcutAction() {
        if panel == nil {
            showPanel()
        }
        if let panel = panel {
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
        }
        // self.textFocusTrigger = true
    }

    func escapeAction() {
        if panel != nil {
            closePanel()
        }
        
    }
    
    func windowDidResignKey(_ notification: Notification) {
//        closePanel()
    }
}

class CustomPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}
