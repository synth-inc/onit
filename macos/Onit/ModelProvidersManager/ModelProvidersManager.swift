//
//  ModelProvidersManager.swift
//  Onit
//
//  Created by Loyd Kim on 7/28/25.
//

import Defaults
import DefaultsMacros
import Foundation

@MainActor
@Observable
class ModelProvidersManager {
    // MARK: - Singleton
    
    static let shared = ModelProvidersManager()
    
    // MARK: - Observables
    
    /// OpenAI

    @ObservableDefault(.useOpenAI)
    @ObservationIgnored
    var useOpenAI: Bool
    
    /// Anthropic
    
    @ObservableDefault(.useAnthropic)
    @ObservationIgnored
    var useAnthropic: Bool
    
    /// XAI
    
    @ObservableDefault(.useXAI)
    @ObservationIgnored
    var useXAI: Bool
    
    /// GoogleAI
    
    @ObservableDefault(.useGoogleAI)
    @ObservationIgnored
    var useGoogleAI: Bool
    
    /// DeepSeek
    
    @ObservableDefault(.useDeepSeek)
    @ObservationIgnored
    var useDeepSeek: Bool
    
    /// Perplexity
    
    @ObservableDefault(.usePerplexity)
    @ObservationIgnored
    var usePerplexity: Bool
    
    /// Custom
    
    @ObservableDefault(.availableCustomProviders)
    @ObservationIgnored
    var availableCustomProvider: [CustomProvider]
    
    // MARK: - Public Variables
    
    var numberRemoteProvidersInUse: Int {
        var count: Int = 0
        
        if useOpenAI { count += 1 }
        if useAnthropic { count += 1 }
        if useXAI { count += 1 }
        if useGoogleAI { count += 1 }
        if useDeepSeek { count += 1 }
        if usePerplexity { count += 1 }
        
        return count
    }
    
    // MARK: - Public Functions
    
    func getIsRemoteProviderInUse(_ provider: AIModel.ModelProvider) -> Bool  {
        switch provider {
        case .openAI:
            return useOpenAI
        case .anthropic:
            return useAnthropic
        case .xAI:
            return useXAI
        case .googleAI:
            return useGoogleAI
        case .deepSeek:
            return useDeepSeek
        case .perplexity:
            return usePerplexity
        case .custom:
            return false
        }
    }
}
