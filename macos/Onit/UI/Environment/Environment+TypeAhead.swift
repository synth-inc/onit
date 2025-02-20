//
//  Environment+TypeAhead.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import SwiftUI

struct TypeAheadStateEnvironmentKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: TypeAheadState = {
        return TypeAheadState.shared
    }()
}

extension EnvironmentValues {
    @MainActor
    var typeAheadState: TypeAheadState {
        get { self[TypeAheadStateEnvironmentKey.self] }
        set { self[TypeAheadStateEnvironmentKey.self] = newValue }
    }
}
