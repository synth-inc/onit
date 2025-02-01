import SwiftUI
import KeyboardShortcuts

extension OnitModel: NSWindowDelegate {
    @MainActor
    func showPanel() {
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
        
        // Position the panel based on mode
        if let screen = NSScreen.main {
            let newFrame: CGRect = {
                switch preferences.windowSizeMode {
                case .default:
                    return getDefaultFrame(for: screen)
                case .userLast:
                    return preferences.contentViewFrame ?? getDefaultFrame(for: screen)
                case .fullScreen:
                    return getFullScreenFrame(for: screen)
                }
            }()
            
            newPanel.setFrame(newFrame, display: false)
            
            // Ensure the panel is visible on screen
            var panelFrame = newPanel.frame
            let visibleFrame = screen.visibleFrame
            
            // Adjust if panel is outside visible area
            if panelFrame.maxX > visibleFrame.maxX - 16 {
                panelFrame.origin.x = visibleFrame.maxX - panelFrame.width - 16
            }
            if panelFrame.minX < visibleFrame.minX + 16 {
                panelFrame.origin.x = visibleFrame.minX + 16
            }
            if panelFrame.maxY > visibleFrame.maxY - 16 {
                panelFrame.origin.y = visibleFrame.maxY - panelFrame.height - 16
            }
            if panelFrame.minY < visibleFrame.minY + 16 {
                panelFrame.origin.y = visibleFrame.minY + 16
            }
            
            newPanel.setFrame(panelFrame, display: false)
            newPanel.makeKeyAndOrderFront(nil)
            newPanel.orderFrontRegardless()
        }

        enableKeyboardShortcuts()

        // Focus the text input when we're activating the panel
        textFocusTrigger = true
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
            let windowWidth = 400
            let windowHeight = 600
            
            let finalXPosition = visibleFrame.origin.x + visibleFrame.width - 16 - windowWidth
            let finalYPosition = visibleFrame.origin.y + visibleFrame.height - 16 - 100
            debugPanel.setFrameOrigin(NSPoint(x: finalXPosition, y: finalYPosition - (windowHeight * 2.0) - 16))
            debugPanel.makeKeyAndOrderFront(nil)
            debugPanel.orderFrontRegardless()
        }
        
        self.debugPanel = debugPanel
    }
    
    func closeDebugWindow() {
        guard let panel = debugPanel else { return }
        panel.orderOut(nil)
        WindowHelper.shared.adjustWindowToTopRight()
        self.debugPanel = nil
    }

    func closePanel() {
        guard let panel = panel else { return }
        panel.orderOut(nil)
        WindowHelper.shared.adjustWindowToTopRight()
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
        }
        if let panel = panel {
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
        }
    }
        
    func launchShortcutAction() {
        launchPanel()
    }
        
    func toggleLocalVsRemoteShortcutAction() {
        updatePreferences { prefs in
            prefs.mode = prefs.mode == .local ? .remote : .local
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
              let contentView = panel.contentView else {
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
        let newY = visibleFrame.origin.y + visibleFrame.height - 16 - newHeight

        // Apply changes
        panel.setFrame(
            NSRect(x: newX, y: newY, width: currentWidth, height: newHeight),
            display: true
        )
    }

    // Get the default window frame in the top-right corner
    private func getDefaultFrame(for screen: NSScreen) -> CGRect {
        let visibleFrame = screen.visibleFrame
        let width: CGFloat = 400
        let height: CGFloat = 600
        
        let x = visibleFrame.maxX - width - 16
        let y = visibleFrame.maxY - height - 16
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    // Get the full screen frame with padding
    private func getFullScreenFrame(for screen: NSScreen) -> CGRect {
        let visibleFrame = screen.visibleFrame
        return CGRect(
            x: visibleFrame.minX + 16,
            y: visibleFrame.minY + 16,
            width: visibleFrame.width - 32,
            height: visibleFrame.height - 32
        )
    }

    @MainActor
    func togglePanelSize() {
        guard let panel = panel,
              let screen = panel.screen ?? NSScreen.main else { return }
        
        // Cycle through modes
        let nextMode: WindowSizeMode = {
            switch preferences.windowSizeMode {
            case .default:
                return .userLast
            case .userLast:
                return .fullScreen
            case .fullScreen:
                return .default
            }
        }()
        
        // Save current frame before changing modes if we're in userLast mode
        if preferences.windowSizeMode == .userLast {
            preferences.contentViewFrame = panel.frame
        }
        
        // Update the mode
        updatePreferences { prefs in
            prefs.windowSizeMode = nextMode
        }
        
        // Apply the new frame based on mode
        let newFrame: CGRect = {
            switch nextMode {
            case .default:
                return getDefaultFrame(for: screen)
            case .userLast:
                return preferences.contentViewFrame ?? getDefaultFrame(for: screen)
            case .fullScreen:
                return getFullScreenFrame(for: screen)
            }
        }()
        
        // Animate to new position
        panel.setFrame(newFrame, display: true, animate: true)
    }
    
    // MARK: - Keyboard Shortcuts
    
    private func enableKeyboardShortcuts() {
        KeyboardShortcuts.enable([.toggleLocalMode,
                                  .newChat,
                                  .resizeWindow,
                                  .toggleModels,
                                  .escape])
    }
    
    private func disableKeyboardShortcuts() {
        KeyboardShortcuts.disable([.toggleLocalMode,
                                   .newChat,
                                   .resizeWindow,
                                   .toggleModels,
                                   .escape])
    }
}

class CustomPanel: NSPanel {
    override var canBecomeKey: Bool {
        return true
    }
}