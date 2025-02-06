//
//  GoogleAIValidationEndpoint.swift
//  Onit
//

import Foundation

struct GoogleAIValidationEndpoint: Endpoint {
    var token: String?
    var timeout: TimeInterval? { nil }

    var baseURL: URL = URL(string: "https://generativelanguage.googleapis.com")!

    typealias Request = EmptyRequest
    typealias Response = GoogleAIValidationResponse

    let apiKey: String

    var path: String { "/v1beta/models" }
    var getParams: [String: String]? {
        ["key": apiKey]
    }
    var method: HTTPMethod { .get }
    var requestBody: EmptyRequest? { nil }
    var additionalHeaders: [String: String]? {
        nil
    }
    //     ["Authorization": "Bearer \(apiKey)"]
    // }
}

struct GoogleAIValidationResponse: Codable {
    let models: [Model]

    struct Model: Codable {
        let name: String
    }
}
