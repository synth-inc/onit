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
                // For custom providers, we'll validate by trying to fetch the models list
                if let customProviderName = Defaults[.remoteModel]?.customProviderName,
                    let customProvider = Defaults[.availableCustomProviders].first(where: {
                        $0.name == customProviderName
                    }),
                    let url = URL(string: customProvider.baseURL)
                {
                    let endpoint = CustomModelsEndpoint(baseURL: url, token: token)
                    _ = try await FetchingClient().execute(endpoint)
                    state.setValid(provider: provider)
                } else {
                    throw FetchingError.invalidURL
                }
            }
            Self.setTokenIsValid(true)
        } catch let error as FetchingError {
            print("Error: \(error.localizedDescription)")
            state.setInvalid(provider: provider, error: error)
        } catch {
            state.setInvalid(provider: provider, error: error)
        }

        tokenValidation = state
    }
    
    static func setTokenIsValid(_ isValid: Bool) {
        if let provider = Defaults[.remoteModel]?.provider {
            setTokenIsValid(isValid, provider: provider)
        }
    }

    static func setTokenIsValid(_ isValid: Bool, provider: AIModel.ModelProvider) {
        if Defaults[.mode] == .local { return }
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
            break
        }
    }

    static func getTokenForModel(_ model: AIModel?) -> String? {
        if let provider = model?.provider {
            switch provider {
            case .openAI:
                return Defaults[.openAIToken]
            case .anthropic:
                return Defaults[.anthropicToken]
            case .xAI:
                return Defaults[.xAIToken]
            case .googleAI:
                return Defaults[.googleAIToken]
            case .deepSeek:
                return Defaults[.deepSeekToken]
            case .perplexity:
                return Defaults[.perplexityToken]
            case .custom:
                return nil
            }
            
        }
        return nil
    }
}
