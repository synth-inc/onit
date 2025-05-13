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
        body: UploadBody = .empty,
        contentType: String? = nil,
        token: String? = nil,
        additionalHeaders: [String: String]? = nil,
        timeout: TimeInterval? = nil
    ) async throws -> Data? {
        print("fetching from \(url)")
        let request = makeRequest(
            from: url,
            method: method,
            body: body,
            contentType: contentType,
            token: token,
            additionalHeaders: additionalHeaders,
            timeout: timeout
        )
        return try await fetchAndHandle(using: request)
    }

    func makeRequest(
        from url: URL,
        method: HTTPMethod,
        body: UploadBody,
        contentType: String?,
        token: String? = nil,
        additionalHeaders: [String: String]?,
        timeout: TimeInterval? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        if case let .data(data) = body {
            request.httpBody = data
        }
        request.addAuthorization(token: token)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.addContentType(for: method, defaultType: contentType ?? "application/json")

        if let timeout = timeout {
            request.timeoutInterval = timeout
        }

        additionalHeaders?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }

    private func fetchAndHandle(using request: URLRequest, file: URL? = nil) async throws -> Data? {
        do {
            let (data, response) = try await fetchDataAndResponse(using: request, file: file)
            try handle(response: response, withData: data)
            return response.mimeType == "application/json" ? data : nil
        } catch let error as FetchingError {
            throw error
        } catch {
            throw FetchingError.networkError(error)
        }
    }

    private func fetchDataAndResponse(
        using request: URLRequest, file: URL? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var (data, response): (Data, URLResponse)
        if let file {
            (data, response) = try await URLSession.shared.upload(for: request, fromFile: file)
        } else {
            (data, response) = try await URLSession.shared.data(for: request)
        }

        let message = parseErrorMessage(from: data) ?? "Client error occurred."
        guard let httpResponse = response as? HTTPURLResponse else {
            throw FetchingError.invalidResponse(message: message)
        }

        return (data, httpResponse)
    }

    func handle(response: HTTPURLResponse, withData data: Data) throws {
        switch response.statusCode {
        case 200...299:
            break
        case 400...499:
            let message = parseErrorMessage(from: data) ?? "Client error occurred."
            if response.statusCode == 401 {
                throw FetchingError.unauthorized(message: message)
            } else if response.statusCode == 403 {
                throw FetchingError.forbidden(message: message)
            } else if response.statusCode == 404 {
                throw FetchingError.notFound(message: message)
            } else {
                throw FetchingError.failedRequest(message: message)
            }
        case 500...599:
            let message = parseErrorMessage(from: data) ?? "Server error occurred."
            throw FetchingError.serverError(statusCode: response.statusCode, message: message)
        default:
            let message = parseErrorMessage(from: data) ?? "An unexpected error occurred."
            throw FetchingError.failedRequest(message: message)
        }
    }

    func parseErrorMessage(from data: Data) -> String? {
        if let errorResponse = try? JSONDecoder().decode(ServerErrorResponse.self, from: data) {
            return errorResponse.message
        }
        return String(data: data, encoding: .utf8)
    }
}
