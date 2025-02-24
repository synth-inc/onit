//
//  Model+Panel.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import Defaults
import KeyboardShortcuts
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
        if Defaults[.createNewChatOnPanelOpen] {
            newChat()
        }

        var windowWidth: CGFloat = 400
        if let savedWidth = Defaults[.panelWidth] {
            // Ensure width is not greater than screen width minus padding
            windowWidth = savedWidth
        }

        let newPanel = CustomPanel(
            contentRect: NSRect(x: 0, y: 0, width: windowWidth, height: 0),
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

        // Position the panel in the top left and set its width
        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame
            let windowHeight = newPanel.frame.height
            var windowWidth = min(newPanel.frame.width, visibleFrame.width)
            
            // Calculate position based on preference
            let finalXPosition: CGFloat
            switch Defaults[.panelPosition] {
            case .topLeft:
                finalXPosition = visibleFrame.origin.x
            case .topCenter:
                finalXPosition = visibleFrame.origin.x + (visibleFrame.width - windowWidth) / 2
            case .topRight:
                finalXPosition = visibleFrame.origin.x + visibleFrame.width - windowWidth
            }
            let finalYPosition = visibleFrame.origin.y + visibleFrame.height - windowHeight
            
            // Set the frame with the new position and width
            let newFrame = NSRect(
                x: finalXPosition, y: finalYPosition, width: windowWidth, height: windowHeight)
            newPanel.setFrame(newFrame, display: false, animate: false)
        }

        newPanel.makeKeyAndOrderFront(nil)
        newPanel.orderFrontRegardless()

        enableKeyboardShortcuts()

        // Focus the text input when we're activating the panel
        self.textFocusTrigger.toggle()

        // Set the defaultPanelFrame to the initial frame of the panel
        Defaults[.defaultPanelFrame] = newPanel.frame
    }

    func openDebugWindow() {
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

        if let screen = NSScreen.main {
            let visibleFrame = screen.visibleFrame
            let defaultPanelFrame = Defaults[.defaultPanelFrame]
            let windowWidth = defaultPanelFrame.width
            let windowHeight = defaultPanelFrame.height

            let finalXPosition = visibleFrame.origin.x + visibleFrame.width - 16 - windowWidth
            let finalYPosition = visibleFrame.origin.y + visibleFrame.height - 16 - 100
            debugPanel.setFrameOrigin(
                NSPoint(x: finalXPosition, y: finalYPosition - (windowHeight * 2.0) - 16))
            debugPanel.makeKeyAndOrderFront(nil)
            debugPanel.orderFrontRegardless()
        }

        self.debugPanel = debugPanel
    }

    func closeDebugWindow() {
        guard let panel = debugPanel else { return }
        panel.orderOut(nil)
        HighlightHintWindowController.shared.adjustWindow()
        self.debugPanel = nil
    }

    func closePanel() {
        guard let panel = panel else { return }

        if !Defaults[.isPanelExpanded] {
            Defaults[.panelWidth] = panel.frame.width
        } else {
            Defaults[.isPanelExpanded] = false
        }

        panel.orderOut(nil)
        HighlightHintWindowController.shared.adjustWindow()
        panel.delegate = nil
        panel.contentView = nil
        self.panel = nil

        disableKeyboardShortcuts()
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
            return
        }

        guard let panel = panel,
            let currentScreen = panel.screen,
            let mouseScreen = NSScreen.screens.first(where: { screen in
                let mouseLocation = NSEvent.mouseLocation
                return screen.frame.contains(mouseLocation)
            }) ?? NSScreen.main
        else {
            // If we can't determine screens, just show the panel
            if let panel = panel {
                panel.makeKeyAndOrderFront(nil)
                panel.orderFrontRegardless()
                self.textFocusTrigger.toggle()
            }
            return
        }

        // If panel is not on the active screen, move it
        if currentScreen != mouseScreen {
            let visibleFrame = mouseScreen.visibleFrame
            let windowHeight = panel.frame.height

            // Get the saved width or use current
            var windowWidth = panel.frame.width
            if let savedWidth = Defaults[.panelWidth] {
                // Ensure width is not greater than screen width minus padding
                windowWidth = min(savedWidth, visibleFrame.width - 32)
            }

            // Calculate position based on preference
            let finalXPosition: CGFloat
            switch Defaults[.panelPosition] {
            case .topLeft:
                finalXPosition = visibleFrame.origin.x + 16
            case .topCenter:
                finalXPosition = visibleFrame.origin.x + (visibleFrame.width - windowWidth) / 2
            case .topRight:
                finalXPosition = visibleFrame.origin.x + visibleFrame.width - windowWidth - 16
            }
            let finalYPosition = visibleFrame.origin.y + visibleFrame.height - windowHeight

            // Set the frame with the new position and width
            let newFrame = NSRect(
                x: finalXPosition, y: finalYPosition, width: windowWidth, height: windowHeight)
            panel.setFrame(newFrame, display: true)
        }

        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()

        self.textFocusTrigger.toggle()
    }

    func launchShortcutAction() {
        if Defaults[.launchShortcutToggleEnabled] {
            togglePanel()
        } else {
            launchPanel()
        }
    }

    func toggleLocalVsRemoteShortcutAction() {
        Defaults[.mode] = Defaults[.mode] == .local ? .remote : .local
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

    func windowDidResignKey(_ notification: Notification) {
        //        closePanel()
    }

    func resizeWindow() {
        togglePanelSize()
    }

    func toggleModelsPanel() {
        showModelSelectionOverlay()
    }

    @MainActor
    func adjustPanelSize() {
        guard let panel = panel,
            let contentView = panel.contentView
        else {
            return
        }
        // Re-measure the SwiftUI hierarchy
        contentView.layoutSubtreeIfNeeded()
        let idealSize = contentView.fittingSize

        // Clamp the window height so it doesn't fall off-screen
        guard let screen = NSScreen.main else { return }
        let visibleFrame = screen.visibleFrame
        let maxAllowedHeight = visibleFrame.height - 16
        let newHeight = min(idealSize.height, maxAllowedHeight)
        let currentWidth = panel.frame.width

        // Keep the top edge in place
        let newX = panel.frame.origin.x
        let newY = visibleFrame.origin.y + visibleFrame.height - newHeight

        // Apply changes
        panel.setFrame(
            NSRect(x: newX, y: newY, width: currentWidth, height: newHeight),
            display: true
        )
    }

    @MainActor
    func togglePanelSize() {
        guard let panel = panel else { return }

        if let screen = panel.screen ?? NSScreen.main {
            let visibleFrame = screen.visibleFrame

            if Defaults[.isPanelExpanded] {
                let defaultPanelFrame = Defaults[.defaultPanelFrame]
                // Restore the panel to its default size and position
                panel.setFrame(defaultPanelFrame, display: true, animate: true)
                // Optionally reposition the panel to its original location
                panel.setFrameOrigin(defaultPanelFrame.origin)
            } else {
                // Save the current panel frame as the default size
                Defaults[.defaultPanelFrame] = panel.frame
                // Expand the panel to fit the screen's visible frame
                panel.setFrame(visibleFrame, display: true, animate: true)
            }
            Defaults[.isPanelExpanded].toggle()
        }
    }

    // MARK: - Keyboard Shortcuts

    private func enableKeyboardShortcuts() {
        KeyboardShortcuts.enable([
            .toggleLocalMode,
            .newChat,
            .resizeWindow,
            .escape,
        ])
    }

    private func disableKeyboardShortcuts() {
        KeyboardShortcuts.disable([
            .toggleLocalMode,
            .newChat,
            .resizeWindow,
            .escape,
        ])
    }
}

class CustomPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}
