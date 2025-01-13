//
//  Model+TokenValidation.swift
//  Onit
//

import Foundation

struct TokenValidationState {
    private var states: [AIModel.ModelProvider: ValidationState] = [:]
    
    enum ValidationState {
        case notValidated
        case validating
        case valid
        case invalid(Error)
        
        var isValidating: Bool {
            if case .validating = self { return true }
            return false
        }
        
        var isValid: Bool {
            if case .valid = self { return true }
            return false
        }
        
        var error: Error? {
            if case .invalid(let error) = self { return error }
            return nil
        }
    }
    
    mutating func setValidating(provider: AIModel.ModelProvider) {
        states[provider] = .validating
    }
    
    mutating func setValid(provider: AIModel.ModelProvider) {
        states[provider] = .valid
    }
    
    mutating func setInvalid(provider: AIModel.ModelProvider, error: Error) {
        states[provider] = .invalid(error)
    }
    
    func state(for provider: AIModel.ModelProvider) -> ValidationState {
        states[provider] ?? .notValidated
    }
}

extension OnitModel {
    var tokenValidation: TokenValidationState {
        get {
            access(keyPath: \.tokenValidation)
            return _tokenValidation
        }
        set {
            withMutation(keyPath: \.tokenValidation) {
                _tokenValidation = newValue
            }
        }
    }
    
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
            }
        } catch let error as FetchingError {
            print("Error: \(error.localizedDescription)")
            state.setInvalid(provider: provider, error: error)
        } catch {
            state.setInvalid(provider: provider, error: error)
        }
        
        tokenValidation = state
    }
}
