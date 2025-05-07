//
//  OnitPanelStateCoordinator.swift
//  Onit
//
//  Created by Kévin Naudin on 06/05/2025.
//

import Combine
import Foundation
import SwiftUI

@MainActor
class OnitPanelStateCoordinator {
    
    // MARK: - Singleton instance
    
    static let shared = OnitPanelStateCoordinator()
    
    // MARK: - Properties
    
    private let accessibilityPermissionManager = AccessibilityPermissionManager.shared
    private let featureFlagManager = FeatureFlagManager.shared
    
    private var frontmostApplicationAtLaunch: NSRunningApplication?
    private var stateChangesCancellable: AnyCancellable?
    
    var state: OnitPanelState {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted ?
            TetherAppsManager.shared.state :
            UntetheredScreenManager.shared.state
    }
    
    var states: [OnitPanelState] {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted ?
            Array(TetherAppsManager.shared.states.values) :
            Array(UntetheredScreenManager.shared.states.values)
    }
    
    var tetherButtonPanelState: OnitPanelState? {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted ?
            TetherAppsManager.shared.tetherButtonPanelState :
            UntetheredScreenManager.shared.tetherButtonPanelState
    }
    
    // MARK: - Private initializer
    
    private init() { }
    
    // MARK: - Functions
    
    func configure(frontmostApplication: NSRunningApplication?) {
        log.error("frontmostApplication: \(frontmostApplication?.localizedName ?? "None")")
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
        switch accessibilityPermission {
        case .granted:
            AccessibilityNotificationsManager.shared.start(pid: frontmostApplicationAtLaunch?.processIdentifier)
            UntetheredScreenManager.shared.stopObserving()
            frontmostApplicationAtLaunch = nil
            
            if FeatureFlagManager.shared.useScreenModeWithAccessibility {
                TetherAppsManager.shared.stopObserving()
                AccessibilityScreenManager.shared.startObserving()
            } else {
                AccessibilityScreenManager.shared.stopObserving()
                TetherAppsManager.shared.startObserving()
            }
        case .denied, .notDetermined:
            TetherAppsManager.shared.stopObserving()
            AccessibilityScreenManager.shared.stopObserving()
            AccessibilityNotificationsManager.shared.stop()
            UntetheredScreenManager.shared.startObserving()
        }
    }
}
