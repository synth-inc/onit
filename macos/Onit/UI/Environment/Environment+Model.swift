//
//  Model+Environment.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import SwiftData
import SwiftUI


private struct ModelEnvironmentKey: @preconcurrency EnvironmentKey {
    @MainActor static var defaultValue: OnitModel = {
        let container = SwiftDataContainer.appContainer
        // TODO: KNA - Check this
        let remoteModels = EnvironmentValues().remoteModels
        let model = OnitModel(container: container, remoteModels: remoteModels)
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
