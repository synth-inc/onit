//
//  TokenValidationEndpoint.swift
//  Onit
//

import Foundation

// OpenAI validation endpoint
struct OpenAIValidationEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.openai.com")!
    
    typealias Request = Never
    typealias Response = OpenAIValidationResponse
    
    var path: String { "/v1/models" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .get }
    var token: String? { nil }
    var requestBody: Never? { nil }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(apiKey)"]
    }
    
    let apiKey: String
}

struct OpenAIValidationResponse: Codable {
    let data: [Model]
    
    struct Model: Codable {
        let id: String
    }
}

// Anthropic validation endpoint
struct AnthropicValidationEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.anthropic.com")!
    
    typealias Request = Never
    typealias Response = AnthropicValidationResponse
    
    var path: String { "/v1/models" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .get }
    var token: String? { nil }
    var requestBody: Never? { nil }
    var additionalHeaders: [String: String]? {
        [
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01"
        ]
    }
    
    let apiKey: String
}

struct AnthropicValidationResponse: Codable {
    let data: [Model]
    let has_more: Bool
    let first_id: String
    let last_id: String
    
    struct Model: Codable {
        let type: String
        let id: String
        let display_name: String
        let created_at: String
    }
}

// xAI validation endpoint
struct XAIValidationEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.x.ai")!
    
    typealias Request = Never
    typealias Response = XAIValidationResponse
    
    var path: String { "/v1/models" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .get }
    var token: String? { nil }
    var requestBody: Never? { nil }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(apiKey)"]
    }
    
    let apiKey: String
}

struct XAIValidationResponse: Codable {
    let data: [Model]
    
    struct Model: Codable {
        let id: String
    }
}
