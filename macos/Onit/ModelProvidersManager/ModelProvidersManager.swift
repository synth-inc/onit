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
    private let authManager = AuthManager.shared
    
    // MARK: - Singleton
    
    static let shared = ModelProvidersManager()
    
    // MARK: - Observables
    
    /// OpenAI

    @ObservableDefault(.useOpenAI)
    @ObservationIgnored
    var useOpenAI: Bool
    
    @ObservableDefault(.openAIToken)
    @ObservationIgnored
    var openAIToken: String?
    
    @ObservableDefault(.isOpenAITokenValidated)
    @ObservationIgnored
    var isOpenAITokenValidated: Bool
    
    /// Anthropic
    
    @ObservableDefault(.useAnthropic)
    @ObservationIgnored
    var useAnthropic: Bool
    
    @ObservableDefault(.anthropicToken)
    @ObservationIgnored
    var anthropicToken: String?
    
    @ObservableDefault(.isAnthropicTokenValidated)
    @ObservationIgnored
    var isAnthropicTokenValidated: Bool
    
    /// XAI
    
    @ObservableDefault(.useXAI)
    @ObservationIgnored
    var useXAI: Bool
    
    @ObservableDefault(.xAIToken)
    @ObservationIgnored
    var xAIToken: String?
    
    @ObservableDefault(.isXAITokenValidated)
    @ObservationIgnored
    var isXAITokenValidated: Bool
    
    /// GoogleAI
    
    @ObservableDefault(.useGoogleAI)
    @ObservationIgnored
    var useGoogleAI: Bool
    
    @ObservableDefault(.googleAIToken)
    @ObservationIgnored
    var googleAIToken: String?
    
    @ObservableDefault(.isGoogleAITokenValidated)
    @ObservationIgnored
    var isGoogleAITokenValidated: Bool
    
    /// DeepSeek
    
    @ObservableDefault(.useDeepSeek)
    @ObservationIgnored
    var useDeepSeek: Bool
    
    @ObservableDefault(.deepSeekToken)
    @ObservationIgnored
    var deepSeekToken: String?
    
    @ObservableDefault(.isDeepSeekTokenValidated)
    @ObservationIgnored
    var isDeepSeekTokenValidated: Bool
    
    /// Perplexity
    
    @ObservableDefault(.usePerplexity)
    @ObservationIgnored
    var usePerplexity: Bool
    
    @ObservableDefault(.perplexityToken)
    @ObservationIgnored
    var perplexityToken: String?
    
    @ObservableDefault(.isPerplexityTokenValidated)
    @ObservationIgnored
    var isPerplexityTokenValidated: Bool
    
    /// Custom
    
    @ObservableDefault(.availableCustomProviders)
    @ObservationIgnored
    var availableCustomProviders: [CustomProvider]
    
    // MARK: - Public Variables
    
    var numberRemoteProvidersInUse: Int {
        var count: Int = 0
        
        if useOpenAI { count += 1 }
        if useAnthropic { count += 1 }
        if useXAI { count += 1 }
        if useGoogleAI { count += 1 }
        if useDeepSeek { count += 1 }
        if usePerplexity { count += 1 }
        
        for customProvider in availableCustomProviders {
            if customProvider.isEnabled { count += 1 }
        }
        
        return count
    }
    
    var userHasRemoteAPITokens: Bool {
        let validCustomProviders = availableCustomProviders.filter(\.isTokenValidated)
        
        return getHasValidRemoteProviderToken(provider: .openAI) ||
            getHasValidRemoteProviderToken(provider: .anthropic) ||
            getHasValidRemoteProviderToken(provider: .xAI) ||
            getHasValidRemoteProviderToken(provider: .googleAI) ||
            getHasValidRemoteProviderToken(provider: .deepSeek) ||
            getHasValidRemoteProviderToken(provider: .perplexity) ||
            !validCustomProviders.isEmpty
    }
    
    // MARK: - Private Functions
    
    private func getCustomRemoteProvider(_ customProviderName: String?) -> CustomProvider? {
        guard let name = customProviderName,
              let customProvider = availableCustomProviders.first(where: { $0.name == name })
        else {
            return nil
        }
        
        return customProvider
    }
    
    private func getIsCustomRemoteProviderInUse(_ customProviderName: String?) -> Bool {
        guard let customProvider = self.getCustomRemoteProvider(customProviderName) else {
            return false
        }
        
        return customProvider.isEnabled
    }
    
    private func getHasValidCustomRemoteProviderToken(_ customProviderName: String?) -> Bool {
        guard let customProvider = self.getCustomRemoteProvider(customProviderName) else {
            return false
        }
        
        return !customProvider.token.isEmpty && customProvider.isTokenValidated
    }
    
    // MARK: - Public Functions
    
    func getIsRemoteProviderInUse(provider: AIModel.ModelProvider, customProviderName: String? = nil) -> Bool  {
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
            return self.getIsCustomRemoteProviderInUse(customProviderName)
        }
    }
    
    func getHasValidRemoteProviderToken(provider: AIModel.ModelProvider, customProviderName: String? = nil) -> Bool {
        switch provider {
        case .openAI:
            guard let token = openAIToken else { return false }
            return !token.isEmpty && isOpenAITokenValidated
        case .anthropic:
            guard let token = anthropicToken else { return false }
            return !token.isEmpty && isAnthropicTokenValidated
        case .xAI:
            guard let token = xAIToken else { return false }
            return !token.isEmpty && isXAITokenValidated
        case .googleAI:
            guard let token = googleAIToken else { return false }
            return !token.isEmpty && isGoogleAITokenValidated
        case .deepSeek:
            guard let token = deepSeekToken else { return false }
            return !token.isEmpty && isDeepSeekTokenValidated
        case .perplexity:
            guard let token = perplexityToken else { return false }
            return !token.isEmpty && isPerplexityTokenValidated
        case .custom:
            return self.getHasValidCustomRemoteProviderToken(customProviderName)
        }
    }
    
    func getCanAccessStandardRemoteProvider(_ provider: AIModel.ModelProvider) -> Bool {
        let isStandardRemoteProviderInUse = getIsRemoteProviderInUse(provider: provider)
        
        if authManager.userLoggedIn {
            return isStandardRemoteProviderInUse
        } else {
            let hasValidStandardRemoteToken = getHasValidRemoteProviderToken(provider: provider)
            return hasValidStandardRemoteToken && isStandardRemoteProviderInUse
        }
    }
}
