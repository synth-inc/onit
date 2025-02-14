//
//  Environment+AutoComplete.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import SwiftUI

struct AutoCompleteStateEnvironmentKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: AutoCompleteState = {
        return AutoCompleteState.shared
    }()
}

extension EnvironmentValues {
    @MainActor
    var autoCompleteState: AutoCompleteState {
        get { self[AutoCompleteStateEnvironmentKey.self] }
        set { self[AutoCompleteStateEnvironmentKey.self] = newValue }
    }
}
