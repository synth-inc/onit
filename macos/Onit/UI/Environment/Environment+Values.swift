//
//  Environment+Values.swift
//  Onit
//
//  Created by Kévin Naudin on 03/02/2025.
//

#if DEBUG
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
    static let defaultValue: AppState = AppState()
}

extension EnvironmentValues {
    var appState: AppState {
        get { self[OnitAppStateKey.self] }
        set { self[OnitAppStateKey.self] = newValue }
    }
    
    var windowState: OnitPanelState? {
        get { 
            if Thread.isMainThread {
                return self[OnitPanelStateKey.self]
            } else {
                print("Environment+ValuesDebug - returning nil for background get")
                return nil
            }
        }
        set { self[OnitPanelStateKey.self] = newValue }
    }
}
