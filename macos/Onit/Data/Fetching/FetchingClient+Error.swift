//
//  FetchingClient+Error.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation

extension FetchingClient {
    public enum FetchingError: Error, Equatable {
        case invalidResponse
        case unauthorized
        case forbidden(String)
        case notFound
        case failedRequest(String)
    }
}

extension FetchingClient.FetchingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "The server received an invalid response."
        case .unauthorized:
            return "Unauthorized request."
        case .failedRequest(let message):
            return message
        case .forbidden(let message):
            return message
        case .notFound:
            return "Could not find resource."
        }
    }
}
