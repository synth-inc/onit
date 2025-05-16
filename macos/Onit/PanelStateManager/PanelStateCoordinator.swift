//
//  PanelStateCoordinator.swift
//  Onit
//
//  Created by Kévin Naudin on 06/05/2025.
//

import Combine
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
            FeatureFlagManager.shared.$useScreenModeWithAccessibility
        )
        .filter { $0.0 != .notDetermined }
        .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        .sink { [weak self] permission, pinnedModeEnabled in
            self?.handleStateChange(accessibilityPermission: permission, pinnedModeEnabled: pinnedModeEnabled)
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
    
    private func handleStateChange(accessibilityPermission: AccessibilityPermissionStatus, pinnedModeEnabled: Bool) {
        AccessibilityAnalytics.logPermission(local: accessibilityPermission)
        
        let oldManager = currentManager
        
        switch accessibilityPermission {
        case .granted:
            if pinnedModeEnabled {
                currentManager = PanelStatePinnedManager.shared
            } else {
                currentManager = PanelStateTetheredManager.shared
            }
        case .denied, .notDetermined:
            currentManager = PanelStateUntetheredManager.shared
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
