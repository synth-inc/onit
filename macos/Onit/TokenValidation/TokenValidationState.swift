//
//  TokenValidationState.swift
//  Onit
//
//  Created by Kévin Naudin on 02/04/2025.
//


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
