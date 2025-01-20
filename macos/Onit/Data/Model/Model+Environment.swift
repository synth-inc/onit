//
//  Model+Environment.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import SwiftUI
import SwiftData

private struct ModelEnvironmentKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: OnitModel = {
        let container = try! ModelContainer(for: Chat.self)
        let model = OnitModel(container: container)
        return model
    }()
}

extension EnvironmentValues {
    @MainActor
    var model: OnitModel {
        get { self[ModelEnvironmentKey.self] }
        set { self[ModelEnvironmentKey.self] = newValue }
    }
}
