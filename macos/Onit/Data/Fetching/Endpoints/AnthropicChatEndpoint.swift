//
//  AnthropicChatEndpoint.swift
//  Onit
//

import Foundation

struct AnthropicChatEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.anthropic.com")!
    
    typealias Request = AnthropicChatRequest
    typealias Response = AnthropicChatResponse
    
    let model: String
    let system: String
    let messages: [AnthropicMessage]
    let maxTokens: Int
    
    var path: String { "/v1/messages" }
    var method: HTTPMethod { .post }
    var token: String? { Token.anthropicToken }
    var requestBody: AnthropicChatRequest? {
        AnthropicChatRequest(
            model: model,
            system: system,
            messages: messages,
            max_tokens: maxTokens
        )
    }
    var additionalHeaders: [String: String]? {
        [
            "x-api-key": Token.anthropicToken ?? "",
            "anthropic-version": "2023-06-01"
        ]
    }
}

struct AnthropicMessage: Codable {
    let role: String
    let content: [AnthropicContent]
}

struct AnthropicContent: Codable {
    let type: String
    let text: String?
    let source: AnthropicImageSource?
}

struct AnthropicImageSource: Codable {
    let type: String
    let media_type: String
    let data: String
}

struct AnthropicChatRequest: Codable {
    let model: String
    let system: String
    let messages: [AnthropicMessage]
    let max_tokens: Int
}

struct AnthropicChatResponse: Codable {
    let content: [AnthropicResponseContent]
    
    struct AnthropicResponseContent: Codable {
        let text: String
    }
}