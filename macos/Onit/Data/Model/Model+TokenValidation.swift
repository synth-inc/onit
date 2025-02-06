//
//  Model+TokenValidation.swift
//  Onit
//

import Defaults
import Foundation

struct TokenValidationState {
  private var states: [AIModel.ModelProvider: ValidationState] = [:]

  enum ValidationState: Equatable {
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

    static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.notValidated, .notValidated): return true
      case (.validating, .validating): return true
      case (.valid, .valid): return true
      case (.invalid, .invalid): return true
      default: return false
      }
    }
  }

  mutating func setNotValidated(provider: AIModel.ModelProvider) {
    states[provider] = .notValidated
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

      case .googleAI:
        let endpoint = GoogleAIValidationEndpoint(apiKey: token)
        _ = try await FetchingClient().execute(endpoint)
        state.setValid(provider: provider)

      case .deepSeek:
        let endpoint = DeepSeekValidationEndpoint(apiKey: token)
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
      setTokenIsValid(true)
    } catch let error as FetchingError {
      print("Error: \(error.localizedDescription)")
      state.setInvalid(provider: provider, error: error)
    } catch {
      state.setInvalid(provider: provider, error: error)
    }

    tokenValidation = state
  }
}
