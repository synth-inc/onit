//
//  ChatSearchEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 5/14/25.
//

import Foundation

extension FetchingClient {
    func getChatSearch(query: String) async throws -> ChatSearchResponse {
        let endpoint = GetChatSearchEndpoint(query: query)
        return try await execute(endpoint)
    }
}

struct GetChatSearchEndpoint: Endpoint {
    typealias Request = ChatSearchRequest

    typealias Response = ChatSearchResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/chat/search" }

    var getParams: [String : String]? { nil }

    var method: HTTPMethod { .post }

    var token: String? { TokenManager.token }

    let query: String

    var requestBody: Request? {
        ChatSearchRequest(query: query)
    }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }

}

struct ChatSearchRequest: Codable {
    let query: String
}

struct ChatSearchResponse: Codable {
    let answer: String?
    let results: [WebSearchResult]
}
