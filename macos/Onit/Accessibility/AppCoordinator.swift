//
//  AppCoordinator.swift
//  Onit
//
//  Created by Kévin Naudin on 15/05/2025.
//

import Combine
import Foundation

/**
 * This class allows us to correctly initialize/configure every singleton related to the accessibility
 */
@MainActor
class AppCoordinator {
    
    // MARK: - Private properties
    
    private let permissionManager: AccessibilityPermissionManager
    private let observerManager: AccessibilityObserversManager
    private let notificationsManager: AccessibilityNotificationsManager
    private let panelStateCoordinator: PanelStateCoordinator
    private let featureFlagManager: FeatureFlagManager

    #if DEBUG || BETA
    private let debugManager : DebugManager
    #endif

    private var stateChangesCancellable: AnyCancellable?
    
    // MARK: - Initializer
    
    init(frontmostPidAtLaunch: pid_t?) {
        // Ensure all singletons are initialized when AppCoordinator is initialized
        permissionManager = AccessibilityPermissionManager.shared
        observerManager = AccessibilityObserversManager.shared
        notificationsManager = AccessibilityNotificationsManager.shared
        panelStateCoordinator = PanelStateCoordinator.shared
        featureFlagManager = FeatureFlagManager.shared
        #if DEBUG || BETA
        debugManager = DebugManager.shared
        #endif
        
        observerManager.delegate = notificationsManager
        
        // Listen to the accessibility permission status changes
        stateChangesCancellable = permissionManager.$accessibilityPermissionStatus
            .filter { $0 != .notDetermined }
            .sink { [weak self] permission in
                self?.handlePermissionStatusChange(permissionStatus: permission)
            }
        
        // Configure everything
        permissionManager.configure()
        panelStateCoordinator.configure(frontmostPidAtLaunch: frontmostPidAtLaunch)
        KeyboardShortcutsManager.configure()
        featureFlagManager.configure()
    }
    
    // MARK: - Private function
    
    private func handlePermissionStatusChange(permissionStatus: AccessibilityPermissionStatus) {
        switch permissionStatus {
        case .granted:
            observerManager.start()
        case .denied:
            observerManager.stop()
            notificationsManager.reset()
        default:
            break
        }
    }
}
