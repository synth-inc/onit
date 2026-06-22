//
//  Environment+Values.swift
//  Onit
//
//  Created by Kévin Naudin on 03/02/2025.
//

#if DEBUG || ONIT_BETA
#if canImport(Darwin)
import Darwin
#endif
#endif

import SwiftUI

private struct OnitPanelStateKey: @preconcurrency EnvironmentKey {
    
    @MainActor
    static let defaultValue: OnitPanelState? = nil
}

private struct OnitAppStateKey: @preconcurrency EnvironmentKey {
    
    @MainActor
    static let defaultValue: AppState = AppState.shared
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[OnitAppStateKey.self] }
        set { self[OnitAppStateKey.self] = newValue }
    }
    
    var windowState: OnitPanelState? {
        get {
            guard Thread.isMainThread else {
                return nil
            }
            return self[OnitPanelStateKey.self]
        }
        set { self[OnitPanelStateKey.self] = newValue }
    }
}
