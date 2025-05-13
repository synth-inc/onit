//
//  Environment+Values.swift
//  Onit
//
//  Created by Kévin Naudin on 03/02/2025.
//

import SwiftUI

private struct OnitPanelStateKey: @preconcurrency EnvironmentKey {
    
    @MainActor
    static let defaultValue: OnitPanelState = OnitPanelState(
        trackedWindow: nil
    )
}

private struct OnitAppStateKey: @preconcurrency EnvironmentKey {
    
    @MainActor
    static let defaultValue: AppState = AppState()
}

extension EnvironmentValues {
    @Entry var systemPrompt: SystemPromptState = SystemPromptState()

    var appState: AppState {
        get { self[OnitAppStateKey.self] }
        set { self[OnitAppStateKey.self] = newValue }
    }
    
    var windowState: OnitPanelState {
        get { self[OnitPanelStateKey.self] }
        set { self[OnitPanelStateKey.self] = newValue }
    }
}
