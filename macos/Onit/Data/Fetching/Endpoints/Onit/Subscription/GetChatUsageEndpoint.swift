//
//  GetChatUsageEndpoint.swift
//  Onit
//
//  Created by Loyd Kim on 5/5/25.
//

import Foundation

extension FetchingClient {
    func getChatUsage() async throws -> ChatUsage? {
        let endpoint = GetChatUsageEndpoint()
        return try await execute(endpoint)
    }
}

struct GetChatUsageEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = ChatUsage?

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/chat/usage" }

    var getParams: [String : String]? { nil }

    var method: HTTPMethod { .get }

    var token: String? { TokenManager.token }

    var requestBody: Request? { nil }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }
}
