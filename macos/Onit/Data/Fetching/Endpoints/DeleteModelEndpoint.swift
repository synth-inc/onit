//
//  LocalChatEndpoint.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Foundation

extension FetchingClient {
    func deleteModel(name: String) async throws {
        let endpoint = DeleteModelEndpoint(name: name)
        let _ = try await execute(endpoint)
    }
}

struct DeleteModelEndpoint: Endpoint {
    var requestBody: DeleteModelRequest?
    
    typealias Request = DeleteModelRequest
    typealias Response = DeleteModelResponse
    var additionalHeaders: [String : String]?
    
    let name: String

    var baseURL: URL = URL(string: "http://localhost:11434")!
    
    var path: String { "/api/delete" }
    var method: HTTPMethod { .delete }
    var token: String? { nil }
}

struct DeleteModelRequest: Codable {
    let name: String
}

struct DeleteModelResponse: Codable {}

