//
//  Model.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

@MainActor @Observable class Model {
    var showMenuBarExtra = false
}

private struct ModelEnvironmentKey: EnvironmentKey {
    @MainActor static var defaultValue: Model = .init()
}

extension EnvironmentValues {
    var model: Model {
        get { self[ModelEnvironmentKey.self] }
        set { self[ModelEnvironmentKey.self] = newValue }
    }
}
