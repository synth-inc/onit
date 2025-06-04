//
//  PanelStateCoordinator.swift
//  Onit
//
//  Created by Kévin Naudin on 06/05/2025.
//

import Combine
import Defaults
import Foundation
import SwiftUI

@MainActor
class PanelStateCoordinator {
    
    // MARK: - Singleton instance
    
    static let shared = PanelStateCoordinator()
    
    // MARK: - Private properties
    
    private var stateChangesCancellable: AnyCancellable?
    private var hasReceivedFirstPermission = false
    private var frontmostPidAtLaunch: pid_t?
    
    // MARK: - Public properties
    
    var currentManager: PanelStateManagerLogic = PanelStateBaseManager()
    var isPanelMovable: Bool { currentManager.isPanelMovable }
    var state: OnitPanelState { currentManager.state }
    var states: [OnitPanelState] { currentManager.states }
    
    // MARK: - Private initializer
    
    private init() { }
    
    // MARK: - Functions
    
    func configure(frontmostPidAtLaunch: pid_t?) {
        self.frontmostPidAtLaunch = frontmostPidAtLaunch
        
        stateChangesCancellable = Publishers.CombineLatest(
            AccessibilityPermissionManager.shared.$accessibilityPermissionStatus,
            FeatureFlagManager.shared.$displayMode
        )
        .filter { $0.0 != .notDetermined }
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] permission, displayMode in
            self?.handleStateChange(accessibilityPermission: permission, displayMode: displayMode)
        }
    }
    
    func getState(for windowHash: UInt) -> OnitPanelState? {
        currentManager.getState(for: windowHash)
    }
    
    func filterHistoryChats(_ allChats: [Chat]) -> [Chat] {
        currentManager.filterHistoryChats(allChats)
    }
    func filterPanelChats(_ allChats: [Chat]) -> [Chat] {
        currentManager.filterPanelChats(allChats)
    }
    
    func launchPanel(for state: OnitPanelState? = nil) {
        let targetState = state ?? self.state
        
        guard targetState !== currentManager.defaultState else { return }
        
        guard let panel = targetState.panel else {
            currentManager.launchPanel(for: targetState)
            return
        }
        
        // This workaround will make the pannel jump on another screen
        if currentManager is PanelStatePinnedManager,
            let mouseScreen = NSScreen.mouse, panel.screen != mouseScreen {
            currentManager.launchPanel(for: targetState)
            return
        }

        // If we're using the shortcut as a Toggle, dismiss the panel.
        if Defaults[.launchShortcutToggleEnabled] {
            closePanel(for: targetState)
        } else {
            panel.show()
            targetState.textFocusTrigger.toggle()
        }
    }
    
    func closePanel(for state: OnitPanelState? = nil) {
        let targetState = state ?? self.state
        
        guard let _ = targetState.panel else { return }
        
        currentManager.closePanel(for: targetState)
    }

    func fetchWindowContext() {
        currentManager.fetchWindowContext()
    }
    
    // MARK: - Private functions
    
    private func handleStateChange(accessibilityPermission: AccessibilityPermissionStatus, displayMode: DisplayMode) {
        AnalyticsManager.Accessibility.permissionChanges(local: accessibilityPermission)

        let oldManager = currentManager

        switch displayMode {
        case .conventional:
            currentManager = PanelStateConventionalManager.shared
        case .pinned:
            currentManager = accessibilityPermission == .granted ? PanelStatePinnedManager.shared : PanelStateUntetheredManager.shared
        case .tethered:
            currentManager = accessibilityPermission == .granted ? PanelStateTetheredManager.shared : PanelStateUntetheredManager.shared
        }
        
        if (oldManager as AnyObject) !== (currentManager as AnyObject) {
            stopAllManagers()
            currentManager.start()
        }
        
        if accessibilityPermission == .granted {
            tryToActivateObserverAtLaunch()
        }
        
        hasReceivedFirstPermission = true
    }
    
    private func stopAllManagers() {
        PanelStateTetheredManager.shared.stop()
        PanelStateUntetheredManager.shared.stop()
        PanelStatePinnedManager.shared.stop()
        PanelStateConventionalManager.shared.stop()
    }
    
    /**
     * When launching Onit with accessibility granted
     * We don't receive the `NSWorkspace.didActivateApplicationNotification` for the active window
     * This is a workaround to activate it and display the hint correctly
     */
    private func tryToActivateObserverAtLaunch() {
        guard let pid = frontmostPidAtLaunch, !hasReceivedFirstPermission else { return }
        
        AccessibilityObserversManager.shared.startAccessibilityObserversOnFirstLaunch(with: pid)
        frontmostPidAtLaunch = nil
    }
}
