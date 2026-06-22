//
//  XAIChatStreamingEndpoint.swift
//  Onit
//

import Foundation
import EventSource

struct XAIChatStreamingEndpoint: StreamingEndpoint {
    var baseURL: URL = URL(string: "https://api.x.ai")!
    
    typealias Request = XAIChatRequest
    typealias Response = XAIChatStreamingResponse
    
    let messages: [XAIChatMessage]
    let model: String
    let token: String?
    
    var path: String { "/v1/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: XAIChatRequest? {
        XAIChatRequest(model: model, messages: messages, stream: true)
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
        let response = try? JSONDecoder().decode(XAIChatStreamingError.self, from: data)
        
        return response?.error
    }
}

struct XAIChatStreamingResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let index: Int
        let delta: Delta
        
        struct Delta: Codable {
            let content: String?
            let role: String?
        }
    }
}

struct XAIChatStreamingError: Codable {
    let error: String
}
