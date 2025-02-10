//
//  FetchingClient+Error.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation

public enum FetchingError: Error {
    case invalidResponse(message: String)
    case invalidRequest(message: String)
    case unauthorized(message: String)
    case forbidden(message: String)
    case notFound(message: String)
    case failedRequest(message: String)
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case networkError(Error)
    case invalidURL
    case noContent
}

extension FetchingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidResponse(let message):
            "Invalid response: \(message)"
        case .invalidRequest(let message):
            "Invalid request: \(message)"
        case .unauthorized(let message):
            "Unauthorized: \(message)."
        case .forbidden(let message):
            "Access forbidden: \(message)"
        case .notFound(let message):
            "Not found: \(message)"
        case .failedRequest(let message):
            "Request failed: \(message)"
        case .serverError(let statusCode, let message):
            "Server error (\(statusCode)): \(message)"
        case .decodingError(let error):
            "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            "Network error: \(error.localizedDescription)"
        case .invalidURL:
            "Invalid URL"
        case .noContent:
            "No content"
        }
    }
}

extension FetchingError: Equatable {
    public static func == (lhs: FetchingError, rhs: FetchingError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidResponse, .invalidResponse),
             (.unauthorized, .unauthorized),
             (.notFound, .notFound),
             (.invalidURL, .invalidURL),
             (.noContent, .noContent):
            return true
        case (.forbidden(let lhsMessage), .forbidden(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.failedRequest(let lhsMessage), .failedRequest(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (
            .serverError(let lhsStatusCode, let lhsMessage),
            .serverError(let rhsStatusCode, let rhsMessage)
        ):
            return lhsStatusCode == rhsStatusCode && lhsMessage == rhsMessage
        case (.decodingError(let lhsError), .decodingError(let rhsError)),
            (.networkError(let lhsError), .networkError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

extension FetchingError: Codable {

    enum CodingKeys: String, CodingKey {
        case type, message, statusCode, description
    }

    enum FetchingErrorType: String, Codable {
        case invalidResponse, invalidRequest, unauthorized, forbidden, notFound, failedRequest,
            serverError, decodingError, networkError, invalidURL, noContent
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(FetchingErrorType.self, forKey: .type)

        switch type {
        case .invalidResponse:
            let message = try container.decode(String.self, forKey: .message)
            self = .invalidResponse(message: message)
        case .invalidRequest:
            let message = try container.decode(String.self, forKey: .message)
            self = .invalidRequest(message: message)
        case .unauthorized:
            let message = try container.decode(String.self, forKey: .message)
            self = .unauthorized(message: message)
        case .forbidden:
            let message = try container.decode(String.self, forKey: .message)
            self = .forbidden(message: message)
        case .notFound:
            let message = try container.decode(String.self, forKey: .message)
            self = .notFound(message: message)
        case .failedRequest:
            let message = try container.decode(String.self, forKey: .message)
            self = .failedRequest(message: message)
        case .serverError:
            let statusCode = try container.decode(Int.self, forKey: .statusCode)
            let message = try container.decode(String.self, forKey: .message)
            self = .serverError(statusCode: statusCode, message: message)
        case .decodingError:
            let errorDescription = try container.decode(String.self, forKey: .description)
            let error = NSError(
                domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            self = .decodingError(error)
        case .networkError:
            let errorDescription = try container.decode(String.self, forKey: .description)
            let error = NSError(
                domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            self = .networkError(error)
        case .invalidURL:
            self = .invalidURL
        case .noContent:
            self = .noContent
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .invalidResponse(let message):
            try container.encode(FetchingErrorType.invalidResponse, forKey: .type)
            try container.encode(message, forKey: .message)
        case .invalidRequest(let message):
            try container.encode(FetchingErrorType.invalidRequest, forKey: .type)
            try container.encode(message, forKey: .message)
        case .unauthorized(let message):
            try container.encode(FetchingErrorType.unauthorized, forKey: .type)
            try container.encode(message, forKey: .message)
        case .forbidden(let message):
            try container.encode(FetchingErrorType.forbidden, forKey: .type)
            try container.encode(message, forKey: .message)
        case .notFound(let message):
            try container.encode(FetchingErrorType.notFound, forKey: .type)
            try container.encode(message, forKey: .message)
        case .failedRequest(let message):
            try container.encode(FetchingErrorType.failedRequest, forKey: .type)
            try container.encode(message, forKey: .message)
        case .serverError(let statusCode, let message):
            try container.encode(FetchingErrorType.serverError, forKey: .type)
            try container.encode(statusCode, forKey: .statusCode)
            try container.encode(message, forKey: .message)
        case .decodingError(let error):
            try container.encode(FetchingErrorType.decodingError, forKey: .type)
            try container.encode(error.localizedDescription, forKey: .description)
        case .networkError(let error):
            try container.encode(FetchingErrorType.networkError, forKey: .type)
            try container.encode(error.localizedDescription, forKey: .description)
        case .invalidURL:
            try container.encode(FetchingErrorType.invalidURL, forKey: .type)
        case .noContent:
            try container.encode(FetchingErrorType.noContent, forKey: .type)
        }
    }
}
