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
    var timeout: TimeInterval? { nil }
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
            "anthropic-version": "2023-06-01",
        ]
    }
    var timeout: TimeInterval? { nil }
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
    var timeout: TimeInterval? { nil }
    let apiKey: String
}

struct XAIValidationResponse: Codable {
    let data: [Model]

    struct Model: Codable {
        let id: String
    }
}

// DeepSeek validation endpoint
struct DeepSeekValidationEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.deepseek.com")!

    typealias Request = Never
    typealias Response = DeepSeekValidationResponse

    var path: String { "/models" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .get }
    var token: String? { nil }
    var requestBody: Never? { nil }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(apiKey)"]
    }
    var timeout: TimeInterval? { nil }
    let apiKey: String
}

struct DeepSeekValidationResponse: Codable {
    let data: [Model]

    struct Model: Codable {
        let id: String
    }
}

// Perplexity validation endpoint
struct PerplexityValidationEndpoint: Endpoint { 
    var baseURL: URL = URL(string: "https://api.perplexity.ai")!

    typealias Request = PerplexityValidationRequest
    typealias Response = PerplexityValidationResponse

    var path: String { "/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var token: String? { nil }
    var requestBody: PerplexityValidationRequest? {
        PerplexityValidationRequest(
            model: "sonar",
            messages: [
                PerplexityValidationMessage(role: "system", content: "Reply with only the word hi and nothing else."),
                PerplexityValidationMessage(role: "user", content: "Hi")
            ]
        )
    }
    var additionalHeaders: [String: String]? {
        [
            "Authorization": "Bearer \(apiKey)",
            "Content-Type": "application/json"
        ]
    }
    var timeout: TimeInterval? { nil }
    let apiKey: String
}

struct PerplexityValidationRequest: Codable {
    let model: String
    let messages: [PerplexityValidationMessage]
}

struct PerplexityValidationMessage: Codable {
    let role: String
    let content: String
}

struct PerplexityValidationResponse: Codable {
    let id: String
}
