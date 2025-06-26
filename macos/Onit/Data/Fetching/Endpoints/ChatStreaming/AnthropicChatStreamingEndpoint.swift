//
//  AnthropicChatStreamingEndpoint.swift
//  Onit
//

import Foundation
import EventSource

struct AnthropicChatStreamingEndpoint: StreamingEndpoint {
    var baseURL: URL = URL(string: "https://api.anthropic.com")!
    
    typealias Request = AnthropicChatRequest
    typealias Response = AnthropicChatStreamingResponse
    
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
            stream: true
        )
    }
    var additionalHeaders: [String: String]? {
        [
            "x-api-key": token ?? "",
            "anthropic-version": "2023-06-01"
        ]
    }
    
    var timeout: TimeInterval? { nil }
    
    func getContentFromSSE(event: EVEvent) throws -> String? {
        
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            if response.contentBlock?.type == "server_tool_use" {
                return "\n\n...\n\n"
            }
            
            return response.delta?.text
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(AnthropicChatStreamingError.self, from: data)
        
        return response?.message
    }
}

struct AnthropicChatStreamingResponse: Codable {
    let type: String
    let delta: Delta?
    let contentBlock: ContentBlock?

    struct Delta: Codable {
        let type: String?
        let text: String?
        let partialJson: String?
        
        enum CodingKeys: String, CodingKey {
            case type, text
            case partialJson = "partial_json"
        }
    }

    struct ContentBlock: Codable {
        let type: String?
    }
    
    enum CodingKeys: String, CodingKey {
        case type
        case delta
        case contentBlock = "content_block"
    }
}

struct AnthropicChatStreamingError: Codable {
    let message: String
}
