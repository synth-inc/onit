//
//  TypeAheadError.swift
//  Onit
//
//  Created by Kévin Naudin on 18/02/2025.
//

import Foundation

enum TypeAheadError: Error, Equatable {
    case noModelConfigured
    case noUserInput
    case completionFailed(String)
    
    static func == (lhs: TypeAheadError, rhs: TypeAheadError) -> Bool {
        switch (lhs, rhs) {
        case (.noModelConfigured, .noModelConfigured):
            return true
        case (.noUserInput, .noUserInput):
            return true
        case (.completionFailed(let lhsMessage), .completionFailed(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }
}

extension TypeAheadError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .noModelConfigured:
            "Please select a model in settings."
        case .noUserInput:
            "Empty input"
        case .completionFailed(let message):
            "Failed: \(message)."
        }
    }
}
