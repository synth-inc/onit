//
//  GoogleAIValidationEndpoint.swift
//  Onit
//

import Foundation

struct GoogleAIValidationEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://generativelanguage.googleapis.com")!
    
    typealias Request = EmptyRequest
    typealias Response = GoogleAIValidationResponse
    
    let apiKey: String
    
    var path: String { "/v1beta/models" }
    var method: HTTPMethod { .get }
    var requestBody: EmptyRequest? { nil }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(apiKey)"]
    }
}

struct GoogleAIValidationResponse: Codable {
    let models: [Model]
    
    struct Model: Codable {
        let name: String
    }
}