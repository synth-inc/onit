//
//  PanelStatePinnedManager+Delegates.swift
//  Onit
//
//  Created by Kévin Naudin on 19/05/2025.
//

import AppKit
import ApplicationServices
import Defaults
import Foundation

extension PanelStatePinnedManager: AccessibilityNotificationsDelegate {
    //  MARK: - DID ACTIVATE WINDOW
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        let previousForegroundWindow = state.foregroundWindow
        state.foregroundWindow = window
        
        // Handle automatic context addition for Pinned mode
        if Defaults[.autoContextOnLaunchPinned] && state.panelOpened {
            log.warning("retrieveWindowContent - didActivateWindow")
            handleAutomaticContextChange(from: previousForegroundWindow, to: window)
        }
        
        guard state.panelOpened, let screen = state.panel?.screen else { return }
        
        /// Introduce a delay, as changing spaces causes simultaneous resizing, resulting in a visual glitch:
        /// 1. The app is resized first by this function from Accessibility
        /// 2. Then by the NSWorkspace.activeSpaceDidChangeNotification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.resizeWindow(for: screen, window: window.element)
        }
    }
    
    //  MARK: - DID ACTIVATE IGNORED WINDOW
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    
    //  MARK: - DID MINIMIZE WINDOW
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    
    //  MARK: - DID DEMINIMIZE WINDOW
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    
    //  MARK: - DID DESTROY WINDOW
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    
    //  MARK: - DID MOVE WINDOW
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {
        guard state.panelOpened else { return }

        let isDragging = checkIfDragStarted(window: window.element)
        
        // Workaround to handle app which reposition automatically the window (Spectacle, Rectangle, ...)
        if !isDragging, let panelScreen = state.panel?.screen {
            resizeWindow(for: panelScreen, window: window.element)
        }
    }
    
    //  MARK: - DID RESIZE WINDOW
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {
        guard state.panelOpened, let screen = state.panel?.screen else { return }
        
        // Prevent the auto-resizing (from Apple) when moving window from one screen to another one
        guard draggingWindow == nil else { return }
        
        // This avoid simultaneous calls when closing the panel which restore the window's frame
        guard state.panel?.isAnimating == false else { return }
        
        resizeWindow(for: screen, window: window.element, windowFrameChanged: true)
    }
    
    //  MARK: - DID CHANGE WINDOW TITLE
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow) {
        if let foregroundWindow = state.foregroundWindow,
           window.element == foregroundWindow.element,
           window.pid == foregroundWindow.pid,
           window.hash == foregroundWindow.hash
        {
            let previousForegroundWindow = state.foregroundWindow
            state.foregroundWindow = window
            
            // Update context if auto context is enabled and this is the current foreground window
            if Defaults[.autoContextOnLaunchPinned] && state.panelOpened {
                log.warning("retrieveWindowContent - didChangeWindowTitle")
                handleAutomaticContextChange(from: previousForegroundWindow, to: window)
            }
        }
    }
    
    var wantsNotificationsFromIgnoredProcesses: Bool { false }
    var wantsNotificationsFromOnit: Bool { false }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeSelection element: AXUIElement, selectedText: String?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeFocusedUIElement element: AXUIElement) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeValue element: AXUIElement) { }
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeactivateApplication appName: String?, processID: pid_t) {}
    
    // MARK: - Automatic Context Management
    
    private func handleAutomaticContextChange(from previousWindow: TrackedWindow?, to newWindow: TrackedWindow) {
        if let previousWindow = previousWindow,
            previousWindow.hash != newWindow.hash || previousWindow.title != newWindow.title {
            removeContextForWindow(previousWindow)
            autoAddContextForWindow(newWindow)
        } else {
            log.warning("retrieveWindowContent - skipping, no change!")
        }
    }
    
    private func removeContextForWindow(_ window: TrackedWindow) {
        // Find and remove any auto context that matches the previous window
        let contextToRemove = state.pendingContextList.first { context in
            if case .auto(let autoContext) = context {
                return autoContext.appHash == window.hash && autoContext.appTitle == window.title
            }
            return false
        }
        
        if let contextToRemove = contextToRemove {
            state.pendingContextList.removeAll { $0 == contextToRemove }
            ContextWindowsManager.shared.deleteContextItem(item: contextToRemove)
        }
        
        // Cancel any pending context fetching tasks for this window to prevent
        // addAutoContext from being called when they complete
        state.cleanupWindowContextTask(uniqueWindowIdentifier: window.hash)
    }
    
    private func autoAddContextForWindow(_ window: TrackedWindow, wasTriggeredAutomatically: Bool = false) {
        // Use the ContextFetchingService to add context for the new window
        ContextFetchingService.shared.retrieveWindowContent(
            state: state,
            trackedWindow: window,
            wasTriggeredAutomatically: true
        )
    }
}

extension PanelStatePinnedManager: OnitPanelStateDelegate {
    func panelBecomeKey(state: OnitPanelState) {
        self.state = state
        // Only enable panel shortcuts if sidebar is enabled
        if Defaults[.enableSidebar] {
            KeyboardShortcutsManager.enablePanelActiveShortcuts(modelContainer: SwiftDataContainer.appContainer)
        }
    }

    func panelResignKey(state: OnitPanelState) {
        // Disable panel-active shortcuts but keep launch shortcuts enabled
        // to allow reopening the panel with the keyboard shortcut.
        // Only manage shortcuts if sidebar is enabled
        if Defaults[.enableSidebar] {
            KeyboardShortcutsManager.disablePanelActiveShortcuts(modelContainer: SwiftDataContainer.appContainer)
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
