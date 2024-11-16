//
//  LocalChatEndpoint.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Foundation

extension FetchingClient {
    func getLocalModels() async throws -> [String] {
        let endpoint = LocalModelsEndpoint()
        let response = try await execute(endpoint)
        return response.tags
    }
}

struct LocalModelsEndpoint: Endpoint {
    var requestBody: EmptyRequest?
    var additionalHeaders: [String : String]?
    
    typealias Request = EmptyRequest
    typealias Response = LocalModelsResponse

    var baseURL: URL = URL(string: "http://localhost:11434")!

    var path: String { "/api/tags" }
    var method: HTTPMethod { .post }
    var token: String? { nil }
}

struct EmptyRequest: Codable {}

struct LocalModelsResponse: Codable {
    let tags: [String]
}
