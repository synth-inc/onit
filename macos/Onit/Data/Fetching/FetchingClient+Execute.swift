//
//  FetchingClient+Execute.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension FetchingClient {
    func execute<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        let url = baseURL.appendingPathComponent(endpoint.path)

        var requestBodyData: Data?
        if let requestBody = endpoint.requestBody {
            requestBodyData = try encoder.encode(requestBody)
        }

        do {
            let data = try await self.data(
                from: url,
                method: endpoint.method,
                body: requestBodyData,
                contentType: "application/json",
                token: endpoint.token,
                additionalHeaders: endpoint.additionalHeaders
            )
            let decodedResponse = try decoder.decode(E.Response.self, from: data)
            return decodedResponse
        } catch let error as DecodingError {
            throw FetchingError.decodingError(error)
        } catch {
            throw error
        }
    }
}
