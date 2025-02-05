//
//  DeepSeekSection.swift
//  Onit
//
//  Created by OpenHands on 2/13/25.
//

import SwiftUI
import Defaults

struct DeepSeekSection: View {
    @Environment(\.model) var model
    @Default(.deepSeekToken) var token
    @Default(.isDeepSeekTokenValidated) var isTokenValidated
    @Default(.useDeepSeek) var useDeepSeek
    @Default(.availableRemoteModels) var availableRemoteModels
    
    var deepSeekModels: [AIModel] {
        availableRemoteModels.filter { $0.provider == .deepSeek }
    }
    
    var body: some View {
        RemoteModelSection(
            provider: .deepSeek,
            token: $token,
            isTokenValidated: $isTokenValidated,
            useProvider: $useDeepSeek,
            models: deepSeekModels
        )
    }
}

#Preview {
    DeepSeekSection()
}