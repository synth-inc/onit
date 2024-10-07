//
//  FetchingClient+Error.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation

public enum FetchingError: Error {
    case invalidResponse
    case unauthorized
    case forbidden(message: String)
    case notFound
    case failedRequest(message: String)
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)
}

extension FetchingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Received an invalid response from the server."
        case .unauthorized:
            "You are not authorized to perform this action."
        case .forbidden(let message):
            "Access forbidden: \(message)"
        case .notFound:
            "The requested resource was not found."
        case .failedRequest(let message):
            "Request failed: \(message)"
        case .serverError(let statusCode, let message):
            "Server error (\(statusCode)): \(message)"
        case .decodingError(let error):
            "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        }
    }
}

extension FetchingError: Equatable {
    public static func == (lhs: FetchingError, rhs: FetchingError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized),
             (.notFound, .notFound):
            return true
        case (.forbidden(let lhsMessage), .forbidden(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.failedRequest(let lhsMessage), .failedRequest(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.serverError(let lhsStatusCode, let lhsMessage), .serverError(let rhsStatusCode, let rhsMessage)):
            return lhsStatusCode == rhsStatusCode && lhsMessage == rhsMessage
        case (.decodingError(let lhsError), .decodingError(let rhsError)),
             (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}
