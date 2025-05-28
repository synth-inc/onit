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
    
    var path: String { "/v1/messages" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    
    var requestBody: AnthropicChatRequest? {
        AnthropicChatRequest(
            model: model,
            system: system,
            messages: messages,
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
        guard let eventString = event.event,
              let dataStart = eventString.range(of: "data: ")?.upperBound else { return nil }
        
        let jsonString = String(eventString[dataStart...]).trimmingCharacters(in: .whitespacesAndNewlines)
        
        if let data = jsonString.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
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

    struct Delta: Codable {
        let type: String?
        let text: String?
        let partialJson: String?
        
        enum CodingKeys: String, CodingKey {
            case type, text
            case partialJson = "partial_json"
        }
    }

    struct Content: Codable {
        let type: String
        let text: String
    }

    struct Usage: Codable {
        let inputTokens: Int
        let outputTokens: Int

        enum CodingKeys: String, CodingKey {
            case inputTokens = "input_tokens"
            case outputTokens = "output_tokens"
        }
    }
}

struct AnthropicChatStreamingError: Codable {
    let message: String
}
