//
//  RemoteModelsState.swift
//  Onit
//
//  Created by Kévin Naudin on 02/02/2025.
//

import Defaults
import DefaultsMacros
import SwiftUI

@Observable
final class RemoteModelsState: ObservableObject {
    @ObservableDefault(.availableRemoteModels)
    @ObservationIgnored
    var availableRemoteModels: [AIModel]
    
    @ObservableDefault(.visibleModelIds)
    @ObservationIgnored
    var visibleModelIds: Set<String>
    
    @ObservableDefault(.useOpenAI)
    @ObservationIgnored
    var useOpenAI: Bool
    
    @ObservableDefault(.useAnthropic)
    @ObservationIgnored
    var useAnthropic: Bool
    
    @ObservableDefault(.useXAI)
    @ObservationIgnored
    var useXAI: Bool
    
    @ObservableDefault(.useGoogleAI)
    @ObservationIgnored
    var useGoogleAI: Bool
    
    var remoteNeedsSetup: Bool {
        !useOpenAI && !useAnthropic && !useXAI && !useGoogleAI
    }

    var listedModels: [AIModel] {
        var models = availableRemoteModels.filter { visibleModelIds.contains($0.id) }

        if !useOpenAI {
            models = models.filter { $0.provider != .openAI }
        }
        if !useAnthropic {
            models = models.filter { $0.provider != .anthropic }
        }
        if !useXAI {
            models = models.filter { $0.provider != .xAI }
        }
        if !useGoogleAI {
            models = models.filter { $0.provider != .googleAI }
        }
        
        // Filter out models from disabled custom providers
        models = models.filter { model in
            if model.provider == .custom,
               let provider = model.customProvider {
                return provider.isEnabled
            }
            return true
        }
        
        return models
    }
}
