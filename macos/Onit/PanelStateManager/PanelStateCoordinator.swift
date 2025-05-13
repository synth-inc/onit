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
    
    private let tetheredManager = PanelStateTetheredManager.shared
    private let untetheredManager = PanelStateUntetheredManager.shared
    private let pinnedManager = PanelStatePinnedManager.shared
    
    private var currentManager: PanelStateManagerLogic = PanelStateBaseManager()
    
    private var frontmostApplicationAtLaunch: NSRunningApplication?
    private var stateChangesCancellable: AnyCancellable?
    
    // MARK: - Public properties
    
    var isPanelMovable: Bool { currentManager.isPanelMovable }
    var state: OnitPanelState { currentManager.state }
    var states: [OnitPanelState] { currentManager.states }
    
    // MARK: - Private initializer
    
    private init() { }
    
    // MARK: - Functions
    
    func configure(frontmostApplication: NSRunningApplication?) {
        frontmostApplicationAtLaunch = frontmostApplication
        
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
        log.error("accessibilityPermission: \(accessibilityPermission), pinnedModeEnabled: \(pinnedModeEnabled)")
        AccessibilityAnalytics.logPermission(local: accessibilityPermission)
        
        let oldManager = currentManager
        
        switch accessibilityPermission {
        case .granted:
            AccessibilityNotificationsManager.shared.start(pid: frontmostApplicationAtLaunch?.processIdentifier)
            frontmostApplicationAtLaunch = nil
            
            if pinnedModeEnabled {
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
