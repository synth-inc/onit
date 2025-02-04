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
            "anthropic-version": "2023-06-01",
        ]
    }
    
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

    var timeout: TimeInterval? { nil }
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
    let stream: Bool
}

struct AnthropicChatResponse: Codable {
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
    
    struct Message: Codable {
        let id: String
        let type: String
        let role: String
        let content: [Content]
        let model: String
        let stopReason: String?
        let stopSequence: String?
        let usage: Usage

        enum CodingKeys: String, CodingKey {
            case id, type, role, content, model
            case stopReason = "stop_reason"
            case stopSequence = "stop_sequence"
            case usage
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
