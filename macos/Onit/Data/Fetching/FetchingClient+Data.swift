//
//  FetchingClient+Data.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation

extension FetchingClient {
    @discardableResult public func data(
        from url: URL,
        method: HTTPMethod = .get,
        body: Data? = nil,
        contentType: String? = nil,
        token: String? = nil,
        additionalHeaders: [String: String]? = nil
    ) async throws -> Data {
        print("fetching from \(url)")
        let request = makeRequest(
            from: url,
            method: method,
            body: body,
            contentType: contentType,
            token: token,
            additionalHeaders: additionalHeaders
        )
        return try await fetchAndHandle(using: request)
    }

    private func makeRequest(
        from url: URL,
        method: HTTPMethod,
        body: Data?,
        contentType: String?,
        token: String?,
        additionalHeaders: [String: String]?
    ) -> URLRequest {
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        request.httpBody = body
        request.addAuthorization(token: token)
        request.addContentType(for: method, defaultType: contentType ?? "application/json")

        additionalHeaders?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func fetchAndHandle(using request: URLRequest) async throws -> Data {
        let (data, response) = try await fetchDataAndResponse(using: request)
        try handle(response: response, withData: data)
        return data
    }

    private func fetchDataAndResponse(using request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        guard let (data, response) = try await URLSession.shared.data(for: request) as? (Data, HTTPURLResponse) else {
            throw FetchingError.invalidResponse
        }
        return (data, response)
    }

    private func handle(response: HTTPURLResponse, withData data: Data) throws {
        switch response.statusCode {
            case config.logoutStatus:
                // nil token
                throw FetchingError.unauthorized
            case config.notFoundStatus:
                throw FetchingError.notFound
            case _ where config.validStatuses.contains(response.statusCode):
                return
            default:
                try throwAppropriateError(using: data, statusCode: response.statusCode)
        }
    }

    private func throwAppropriateError(using data: Data, statusCode: Int) throws {
//        if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
//            throw FetchingError.failedRequest(errorResponse.message)
//        } else {
            let rawResponse = String(data: data, encoding: .utf8) ?? "No response body"
            throw FetchingError.failedRequest(
                "Unknown error occurred. Status Code: \(statusCode), Response: \(rawResponse)")
//        }
    }
}
