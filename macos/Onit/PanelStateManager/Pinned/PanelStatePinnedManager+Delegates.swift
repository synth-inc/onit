//
//  PanelStatePinnedManager+Delegates.swift
//  Onit
//
//  Created by Kévin Naudin on 19/05/2025.
//

import AppKit

extension PanelStatePinnedManager: AccessibilityNotificationsDelegate {
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        guard state.panelOpened, let screen = state.panel?.screen else { return }
        
        /// Introduce a delay, as changing spaces causes simultaneous resizing, resulting in a visual glitch:
        /// 1. The app is resized first by this function from Accessibility
        /// 2. Then by the NSWorkspace.activeSpaceDidChangeNotification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.resizeWindow(for: screen, window: window.element)
        }
    }
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {
        guard state.panelOpened else { return }

        let isDragging = checkIfDragStarted(window: window.element)
        
        // Workaround to handle app which reposition automatically the window (Spectacle, Rectangle, ...)
        if !isDragging, let panelScreen = state.panel?.screen {
            resizeWindow(for: panelScreen, window: window.element)
        }
    }
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {
        guard state.panelOpened, let screen = state.panel?.screen else { return }
        
        // Prevent the auto-resizing (from Apple) when moving window from one screen to another one
        guard draggingWindow == nil else { return }
        
        // This avoid simultaneous calls when closing the panel which restore the window's frame
        guard state.panel?.isAnimating == false else { return }
        
        resizeWindow(for: screen, window: window.element, windowFrameChanged: true)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow) {}
}

extension PanelStatePinnedManager: OnitPanelStateDelegate {
    func panelBecomeKey(state: OnitPanelState) {
        self.state = state
        KeyboardShortcutsManager.enable(modelContainer: SwiftDataContainer.appContainer)
        
        // Tracks when Onit app goes into foreground.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .panelDidBecomeKey, object: state)
        }
    }
    
    func panelResignKey(state: OnitPanelState) {
        KeyboardShortcutsManager.disable(modelContainer: SwiftDataContainer.appContainer)
        
        // Tracks when Onit app goes into background.
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .panelDidResignKey, object: state)
        }
    }
    
    func panelStateDidChange(state: OnitPanelState) {
        if !state.panelOpened {
            state.trackedScreen = nil
            
            activateMouseScreen(forced: true)
        } else {
            state.panel?.setLevel(.floating)
        }
    }
    
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) {}
}
