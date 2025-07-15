//
//  GoogleAIChatStreamingEndpoint.swift
//  Onit
//

import Foundation
import EventSource

struct GoogleAIChatStreamingEndpoint: StreamingEndpoint {
    var baseURL: URL = URL(string: "https://generativelanguage.googleapis.com")!
    
    typealias Request = GoogleAIChatRequest
    typealias Response = GoogleAIChatStreamingResponse
    
    let messages: [GoogleAIChatMessage]
    let model: String
    let token: String?
    
    var path: String { "/v1beta:chatCompletions" } 
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: GoogleAIChatRequest? {
        GoogleAIChatRequest(model:model, messages: messages, stream: true, n: 1)
    }
    
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    
    var timeout: TimeInterval? { nil }
    
    func getContentFromSSE(event: EVEvent) throws -> StreamingEndpointResponse? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            if let content = response.choices.first?.delta.content {
                return StreamingEndpointResponse(content: content, toolName: nil, toolArguments: nil)
            }
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(GoogleAIChatStreamingError.self, from: data)
        
        return response?.error.message
    }
}

struct GoogleAIChatStreamingResponse: Codable {
    let choices: [Choice]
    
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

struct GoogleAIChatStreamingError: Codable {
    struct Error: Codable {
        let message: String
    }
    
    let error: Error
}
