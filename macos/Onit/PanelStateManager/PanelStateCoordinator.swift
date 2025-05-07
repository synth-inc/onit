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
    
    // MARK: - Properties
    
    private let accessibilityPermissionManager = AccessibilityPermissionManager.shared
    private let featureFlagManager = FeatureFlagManager.shared
    
    private let tetheredManager = PanelStateTetheredManager.shared
    private let untetheredManager = PanelStateUntetheredManager.shared
    private let pinnedManager = PanelStatePinnedManager.shared
    
    private var frontmostApplicationAtLaunch: NSRunningApplication?
    private var stateChangesCancellable: AnyCancellable?
    
    private var currentManager: PanelStateManagerLogic = PanelStateBaseManager()
    
    var state: OnitPanelState { currentManager.state }
    var states: [OnitPanelState] { currentManager.states }
    var tetherButtonPanelState: OnitPanelState? { currentManager.tetherButtonPanelState }
    
    // MARK: - Private initializer
    
    private init() { }
    
    // MARK: - Functions
    
    func configure(frontmostApplication: NSRunningApplication?) {
        frontmostApplicationAtLaunch = frontmostApplication
        
        stateChangesCancellable = Publishers.CombineLatest(
            accessibilityPermissionManager.$accessibilityPermissionStatus,
            featureFlagManager.$useScreenModeWithAccessibility
        ).sink { [weak self] permission, pinnedModeEnabled in
            self?.handleStateChange(accessibilityPermission: permission, pinnedModeEnabled: pinnedModeEnabled)
        }
    }
    
    private func handleStateChange(accessibilityPermission: AccessibilityPermissionStatus, pinnedModeEnabled: Bool) {
        log.error("accessibilityPermission: \(accessibilityPermission), pinnedModeEnabled: \(pinnedModeEnabled)")
        AccessibilityAnalytics.logPermission(local: accessibilityPermission)
        
        let oldManager = currentManager
        
        switch accessibilityPermission {
        case .granted:
            AccessibilityNotificationsManager.shared.start(pid: frontmostApplicationAtLaunch?.processIdentifier)
            frontmostApplicationAtLaunch = nil
            
            if FeatureFlagManager.shared.useScreenModeWithAccessibility {
                currentManager = pinnedManager
            } else {
                currentManager = tetheredManager
            }
        case .denied, .notDetermined:
            AccessibilityNotificationsManager.shared.stop()
            currentManager = untetheredManager
        }
        
        if (oldManager as AnyObject) !== (currentManager as AnyObject) {
            stopAllManagers()
            currentManager.start()
        }
    }
    
    private func stopAllManagers() {
        tetheredManager.stop()
        untetheredManager.stop()
        pinnedManager.stop()
    }
}
