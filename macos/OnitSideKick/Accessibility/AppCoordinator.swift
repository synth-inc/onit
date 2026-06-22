//
//  AppCoordinator.swift
//  Onit
//
//  Created by Kévin Naudin on 15/05/2025.
//

import Combine
import Defaults
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

    #if DEBUG || ONIT_BETA
    private let debugManager: DebugManager
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

        #if DEBUG || ONIT_BETA
        debugManager = DebugManager.shared
        #endif

        observerManager.addDelegate(notificationsManager)

        // Listen to the accessibility permission status changes
        stateChangesCancellable = permissionManager.$accessibilityPermissionStatus
            .filter { $0 != .notDetermined }
            .sink { [weak self] permission in
                self?.handlePermissionStatusChange(permissionStatus: permission)
            }

        // Configure everything
        permissionManager.configure()
        // KeyboardShortcutsManager must be configured before PanelStateCoordinator
        // because PanelStateCoordinator's Combine publisher may enable shortcuts
        KeyboardShortcutsManager.configure()
        panelStateCoordinator.configure(frontmostPidAtLaunch: frontmostPidAtLaunch)
        HintManager.shared.configure()
        featureFlagManager.configure()
    }

    // MARK: - Private function

    private func handlePermissionStatusChange(permissionStatus: AccessibilityPermissionStatus) {
        switch permissionStatus {
        case .granted:
            observerManager.start()
            EscapeKeyManager.shared.startMonitoring()
        case .denied:
            observerManager.stop()
            notificationsManager.reset()
            EscapeKeyManager.shared.stopMonitoring()
        default:
            break
        }
    }

    // MARK: - Cleanup

    func cleanup() {
        stateChangesCancellable?.cancel()
        AccessibilityParsingManager.shared.cleanup()
        permissionManager.cleanup()
    }
}
