//
//  Environment+Values.swift
//  Onit
//
//  Created by Kévin Naudin on 03/02/2025.
//

import SwiftUI

private struct OnitPanelStateKey: EnvironmentKey {
    
    static let defaultValue: OnitPanelState = {
        if Thread.isMainThread {
            return MainActor.assumeIsolated {
                let state = OnitPanelState()
                state.defaultEnvironmentSource = "EnvironmentKey"
                return state
            }
        } else {
            var state: OnitPanelState?
            let semaphore = DispatchSemaphore(value: 0)
            
            Task { @MainActor in
                state = OnitPanelState()
                state?.defaultEnvironmentSource = "EnvironmentKey"
                semaphore.signal()
            }
            
            semaphore.wait()
            return state!
        }
    }()
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
    
    var windowState: OnitPanelState {
        get { self[OnitPanelStateKey.self] }
        set { self[OnitPanelStateKey.self] = newValue }
    }
}
