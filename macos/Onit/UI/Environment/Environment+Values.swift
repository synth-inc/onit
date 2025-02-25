//
//  Environment+Values.swift
//  Onit
//
//  Created by Kévin Naudin on 03/02/2025.
//

import SwiftUI

extension EnvironmentValues {
    @Entry var remoteModels: RemoteModelsState = RemoteModelsState()
    @Entry var systemPrompt: SystemPromptState = SystemPromptState()
}
