//
//  Environment+RemoteModels.swift
//  Onit
//
//  Created by Kévin Naudin on 03/02/2025.
//

import SwiftUI

struct RemoteModelsEnvironmentKey: @preconcurrency EnvironmentKey {
  @MainActor static var defaultValue: RemoteModelsState = {
    return RemoteModelsState()
  }()
}

extension EnvironmentValues {
  @MainActor
  var remoteModels: RemoteModelsState {
    get { self[RemoteModelsEnvironmentKey.self] }
    set { self[RemoteModelsEnvironmentKey.self] = newValue }
  }
}
