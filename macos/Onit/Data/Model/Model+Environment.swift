//
//  Model+Environment.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import SwiftUI

private struct ModelEnvironmentKey: EnvironmentKey {
    @MainActor static var defaultValue: OnitModel = .init()
}

extension EnvironmentValues {
    var model: OnitModel {
        get { self[ModelEnvironmentKey.self] }
        set { self[ModelEnvironmentKey.self] = newValue }
    }
}
