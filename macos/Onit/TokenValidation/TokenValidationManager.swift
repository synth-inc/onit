//
//  TokenValidationManager.swift
//  Onit
//
//  Created by Kévin Naudin on 02/04/2025.
//

import Defaults
import Foundation

@MainActor
class TokenValidationManager {
    
    // MARK: - Singleton
    
    static let shared = TokenValidationManager()
    
    // MARK: - Properties
    
    var tokenValidation = TokenValidationState()
    
    // MARK: - Functions

    @MainActor
    func validateToken(provider: AIModel.ModelProvider, token: String) async {
        var state = tokenValidation
        state.setValidating(provider: provider)
        tokenValidation = state

        do {
            switch provider {
            case .openAI:
                let endpoint = OpenAIValidationEndpoint(apiKey: token)
                _ = try await FetchingClient().execute(endpoint)
                state.setValid(provider: provider)
                
            case .anthropic:
                let endpoint = AnthropicValidationEndpoint(apiKey: token)
                _ = try await FetchingClient().execute(endpoint)
                state.setValid(provider: provider)
                
            case .xAI:
                let endpoint = XAIValidationEndpoint(apiKey: token)
                _ = try await FetchingClient().execute(endpoint)
                state.setValid(provider: provider)
                
            case .googleAI:
                let endpoint = GoogleAIValidationEndpoint(apiKey: token)
                _ = try await FetchingClient().execute(endpoint)
                state.setValid(provider: provider)
                
            case .deepSeek:
                let endpoint = DeepSeekValidationEndpoint(apiKey: token)
                _ = try await FetchingClient().execute(endpoint)
                state.setValid(provider: provider)
                
            case .perplexity:
                let endpoint = PerplexityValidationEndpoint(apiKey: token)
                _ = try await FetchingClient().execute(endpoint)
                state.setValid(provider: provider)
                
            case .custom:
                throw FetchingError.invalidRequest(message: "Custom provider token validation is not supported")   
            }
            Self.setTokenIsValid(true, provider: provider)
        } catch let error as FetchingError {
            print("Error: \(error.localizedDescription)")
            state.setInvalid(provider: provider, error: error)
            Self.setTokenIsValid(false, provider: provider)
        } catch {
            state.setInvalid(provider: provider, error: error)
            Self.setTokenIsValid(false, provider: provider)
        }

        tokenValidation = state
    }
    
    static func setTokenIsValid(_ isValid: Bool) {
        if let provider = Defaults[.remoteModel]?.provider {
            setTokenIsValid(isValid, provider: provider)
        }
    }

    static func setTokenIsValid(_ isValid: Bool, provider: AIModel.ModelProvider) {
        switch provider {
        case .openAI:
            Defaults[.isOpenAITokenValidated] = isValid
        case .anthropic:
            Defaults[.isAnthropicTokenValidated] = isValid
        case .xAI:
            Defaults[.isXAITokenValidated] = isValid
        case .googleAI:
            Defaults[.isGoogleAITokenValidated] = isValid
        case .deepSeek:
            Defaults[.isDeepSeekTokenValidated] = isValid
        case .perplexity:
            Defaults[.isPerplexityTokenValidated] = isValid
        case .custom:
            if let customProviderName = Defaults[.remoteModel]?.customProviderName,
               let index = Defaults[.availableCustomProviders].firstIndex(where: { $0.name == customProviderName }) {
                Defaults[.availableCustomProviders][index].isTokenValidated = isValid
            }
        }
    }

    static func getTokenForProviderOrModel(provider: AIModel.ModelProvider? = nil, model: AIModel? = nil) -> String? {
        if let provider = provider ?? model?.provider {
            switch provider {
            case .openAI:
                return Defaults[.isOpenAITokenValidated] ? Defaults[.openAIToken] : nil
            case .anthropic:
                return Defaults[.isAnthropicTokenValidated] ? Defaults[.anthropicToken] : nil
            case .xAI:
                return Defaults[.isXAITokenValidated] ? Defaults[.xAIToken] : nil
            case .googleAI:
                return Defaults[.isGoogleAITokenValidated] ? Defaults[.googleAIToken] : nil
            case .deepSeek:
                return Defaults[.isDeepSeekTokenValidated] ? Defaults[.deepSeekToken] : nil
            case .perplexity:
                return Defaults[.isPerplexityTokenValidated] ? Defaults[.perplexityToken] : nil
            case .custom:
                if let customProviderName = model?.customProviderName,
                   let customProvider = Defaults[.availableCustomProviders].first(where: { $0.name == customProviderName }),
                   customProvider.isTokenValidated {
                    return customProvider.token
                }
                return nil
            }
        }
        return nil
    }
}
