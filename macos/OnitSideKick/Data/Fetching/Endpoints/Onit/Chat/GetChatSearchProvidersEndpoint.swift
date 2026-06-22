//
//  GetChatSearchProvidersEndpoint.swift
//  Onit
//
//  Created by Jay Swanson on 6/25/25.
//

import Foundation

extension FetchingClient {
    func getChatSearchProviders() async throws -> [String] {
        let endpoint = GetChatSearchProvidersEndpoint()
        let response = try await execute(endpoint)
        return response.providers
    }
}

struct GetChatSearchProvidersEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = GetChatSearchProvidersResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/chat/search-providers" }

    var getParams: [String: String]? { nil }

    var method: HTTPMethod { .get }

    var token: String? { TokenManager.token }

    var requestBody: Request? { nil }

    var additionalHeaders: [String: String]? { nil }

    var timeout: TimeInterval? { nil }

}

struct GetChatSearchProvidersResponse: Codable {
    let providers: [String]
}
