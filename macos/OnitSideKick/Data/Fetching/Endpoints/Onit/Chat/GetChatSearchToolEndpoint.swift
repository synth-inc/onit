//
//  GetChatSearchToolEndpoint.swift
//  Onit
//
//  Created by Jay Swanson on 7/15/25.
//

import Foundation

extension FetchingClient {
    func getChatSearchTool(provider: String) async throws -> ChatSearchTool {
        let endpoint = GetChatSearchToolEndpoint(provider: provider)
        return try await execute(endpoint)
    }
}

struct GetChatSearchToolEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = ChatSearchTool

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/chat/search-tool" }

    let provider: String

    var getParams: [String: String]? {
        [
            "provider": provider
        ]
    }

    var method: HTTPMethod { .get }

    var token: String? { TokenManager.token }

    var requestBody: Request? { nil }

    var additionalHeaders: [String: String]? { nil }

    var timeout: TimeInterval? { nil }

}

struct ChatSearchTool: Codable {
    let type: String?
    let name: String?
    let maxUses: Int?

    enum CodingKeys: String, CodingKey {
        case type
        case name
        case maxUses = "max_uses"
    }
}
