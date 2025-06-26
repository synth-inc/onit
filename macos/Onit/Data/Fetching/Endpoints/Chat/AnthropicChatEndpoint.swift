//
//  AnthropicChatEndpoint.swift
//  Onit
//

import Foundation
import EventSource

struct AnthropicChatEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.anthropic.com")!

    typealias Request = AnthropicChatRequest
    typealias Response = AnthropicChatResponse

    let model: String
    let system: String
    let token: String?
    let messages: [AnthropicMessage]
    let maxTokens: Int
    let includeSearch: Bool?

    var path: String { "/v1/messages" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }

    var requestBody: AnthropicChatRequest? {
        var tools: [AnthropicChatTool] = []
        if includeSearch == true {
            tools.append(AnthropicChatTool.search(maxUses: 5))
        }
        return AnthropicChatRequest(
            model: model,
            system: system,
            messages: messages,
            tools: tools,
            max_tokens: maxTokens,
            stream: false
        )
    }
    var additionalHeaders: [String: String]? {
        [
            "x-api-key": token ?? "",
            "anthropic-version": "2023-06-01",
        ]
    }
    var timeout: TimeInterval? { nil }
    
    func getContent(response: Response) -> String? {
        return response.content.first?.text
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
    let tools: [AnthropicChatTool]
    let max_tokens: Int
    let stream: Bool
}

struct AnthropicChatTool: Codable {
    let type: String
    let name: String
    let maxUses: Int
    
    enum CodingKeys: String, CodingKey {
        case type
        case name
        case maxUses = "max_uses"
    }

    static func search(maxUses: Int) -> AnthropicChatTool {
        return AnthropicChatTool(type: "web_search_20250305", name: "web_search", maxUses: maxUses)
    }
}

struct AnthropicChatResponse: Codable {
    let content: [AnthropicResponseContent]
    
    struct AnthropicResponseContent: Codable {
        let text: String
    }
}
