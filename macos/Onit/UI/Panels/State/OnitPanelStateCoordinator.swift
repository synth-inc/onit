//
//  OnitPanelStateCoordinator.swift
//  Onit
//
//  Created by Kévin Naudin on 06/05/2025.
//

@MainActor
class OnitPanelStateCoordinator {
    
    // MARK: - Singleton instance
    
    static let shared = OnitPanelStateCoordinator()
    
    // MARK: - Properties
    
    private let accessibilityPermissionManager = AccessibilityPermissionManager.shared
    
    var state: OnitPanelState {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted ?
            TetherAppsManager.shared.state :
            UntetheredScreenManager.shared.state
    }
    
    var states: [OnitPanelState] {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted ?
            TetherAppsManager.shared.states.map { $0.1 } :
            UntetheredScreenManager.shared.states.map { $0.1 }
    }
    
    var tetherButtonPanelState: OnitPanelState? {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted ?
            TetherAppsManager.shared.tetherButtonPanelState :
            UntetheredScreenManager.shared.tetherButtonPanelState
    }
    
    // MARK: - Private initializer
    
    private init() { }
}
