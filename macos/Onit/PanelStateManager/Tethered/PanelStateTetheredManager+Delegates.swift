//
//  PanelStateTetheredManager+Delegates.swift
//  Onit
//
//  Created by Kévin Naudin on 18/04/2025.
//

// MARK: - AccessibilityNotificationsDelegate

import Foundation

extension PanelStateTetheredManager: AccessibilityNotificationsDelegate {
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        log.debug("activate window")
        let panelState = getState(for: window)
        
        handlePanelStateChange(state: panelState, action: .activate)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {
        log.debug("activate ignored window")
        hideTetherWindow()
        updateLevelState(trackedWindow: window)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {
        log.debug("minimize window")
        if let (_, state) = statesByWindow.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == window
        }) {
            state.hidden = true
            handlePanelStateChange(state: state, action: .undefined)
            state.panelWasHidden = true
        }
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {
        log.debug("deminimize window")
        if let (_, state) = statesByWindow.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == window
        }) {
            state.hidden = false
            handlePanelStateChange(state: state, action: .resize)
            state.panelWasHidden = false
        }
    }
        
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {
        log.debug("destroy window")
        if let (_, state) = statesByWindow.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == window
        }) {
            PanelStateCoordinator.shared.closePanel(for: state)
            state.removeDelegate(self)
            statesByWindow.removeValue(forKey: window)
        }
        
        hideTetherWindow()
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {
        log.debug("move window")
        let panelState = getState(for: window)
        
        handlePanelStateChange(state: panelState, action: .move)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {
        log.debug("resize window")
        let panelState = getState(for: window)
        
        handlePanelStateChange(state: panelState, action: .resize)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow) {}
}

// MARK: - OnitPanelStateDelegate

extension PanelStateTetheredManager: OnitPanelStateDelegate {
    
    func panelBecomeKey(state: OnitPanelState) {
        func foregroundTrackedWindowIfNeeded(state: OnitPanelState) {
            guard let panel = state.panel, panel.level != .floating else { return }
            guard let (trackedWindow, _) = statesByWindow.first(where: { $0.value === state }) else {
                return
            }
            
            trackedWindow.element.bringToFront()
            handlePanelStateChange(state: state, action: .undefined)
        }
        
        self.state = state
        foregroundTrackedWindowIfNeeded(state: state)
        
        // Tracks when Onit app goes into foreground.
        NotificationCenter.default.post(name: .panelDidBecomeKey, object: state)
    }
    
    func panelResignKey(state: OnitPanelState) {
        // Tracks when Onit app goes into background.
        NotificationCenter.default.post(name: .panelDidResignKey, object: state)
    }
    
    func panelStateDidChange(state: OnitPanelState) {
        handlePanelStateChange(state: state, action: .undefined)
    }
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) { }
}

