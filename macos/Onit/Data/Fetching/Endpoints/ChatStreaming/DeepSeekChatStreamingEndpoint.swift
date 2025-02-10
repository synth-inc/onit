//
//  DeepSeekChatStreamingEndpoint.swift
//  Onit
//
//  Created by OpenHands on 2/13/25.
//

import EventSource
import Foundation

struct DeepSeekChatStreamingEndpoint: StreamingEndpoint {
    typealias Request = DeepSeekChatRequest
    typealias Response = DeepSeekChatStreamingResponse
    
    let messages: [DeepSeekChatMessage]
    let model: String
    let token: String?
    
    var baseURL: URL {
        URL(string: "https://api.deepseek.com")!
    }
    
    var path: String { "/v1/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    
    var requestBody: DeepSeekChatRequest? {
        DeepSeekChatRequest(model: model, messages: messages, stream: true)
    }
    
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    var timeout: TimeInterval? { nil }
    
    func getContentFromSSE(event: EVEvent) throws -> String? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            return response.choices.first?.delta.content
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(DeepSeekChatStreamingError.self, from: data)
        
        return response?.error.message
    }
}

struct DeepSeekChatStreamingResponse: Codable {
    let choices: [Choice]
    let created: Int
    let id: String
    let model: String
    let object: String
    
    struct Choice: Codable {
        let delta: Delta
        let index: Int
            
        enum CodingKeys: String, CodingKey {
            case delta
            case index
        }
    }
        
    struct Delta: Codable {
        let content: String?
        let role: String?
    }
}

struct DeepSeekChatStreamingError: Codable {
    let error: ErrorMessage
    
    struct ErrorMessage: Codable {
        let message: String
    }
}
