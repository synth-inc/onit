//
//  LocalChatEndpoint.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Defaults
import Foundation

extension FetchingClient {
    func getLocalModels() async throws -> [String] {
        let endpoint = LocalModelsEndpoint()

        let response = try await execute(endpoint)
        let names = response.models.map { $0.name }
        return names
    }
}

struct LocalModelsEndpoint: Endpoint {
    var requestBody: EmptyRequest?
    var additionalHeaders: [String : String]?
    
    typealias Request = EmptyRequest
    typealias Response = LocalModelsResponse

    var baseURL: URL {
        var url: URL!
        DispatchQueue.main.sync {
            url = Defaults[.localEndpointURL]
        }
        return url
    }

    var path: String { "/api/tags" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .get }
    var token: String? { nil }
    var timeout: TimeInterval? { nil }
}

struct EmptyRequest: Codable {}

struct LocalModelsResponse: Codable {
    let models: [LocalModelResponse]
}

struct LocalModelResponse: Codable {
    let name: String
    let model: String
    let modifiedAt: Date?
    let size: Int64
    let digest: String
    let details: ModelDetails
}

struct ModelDetails: Codable {
    let parentModel: String?
    let format: String?
    let family: String?
    let families: [String]?
    let parameterSize: String?
    let quantizationLevel: String?
}
