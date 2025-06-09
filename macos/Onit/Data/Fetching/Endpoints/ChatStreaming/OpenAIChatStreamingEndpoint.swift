//
//  OpenAIChatStreamingEndpoint.swift
//  Onit
//

import Foundation
import EventSource

struct OpenAIChatStreamingEndpoint: StreamingEndpoint {
    var baseURL: URL = URL(string: "https://api.openai.com")!
    
    typealias Request = OpenAIChatRequest
    typealias Response = OpenAIChatStreamingResponse
    
    let messages: [OpenAIChatMessage]
    let token: String?
    let model: String
    
    var path: String { "/v1/responses" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: OpenAIChatRequest? {
        OpenAIChatRequest(model: model, input: messages, stream: true)
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    
    var timeout: TimeInterval? { nil }
    
    func getContentFromSSE(event: EVEvent) throws -> String? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            return response.delta
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(OpenAIChatStreamingError.self, from: data)
        
        return response?.error.message
    }
}

struct OpenAIChatStreamingResponse: Codable {
    let delta: String?
}

struct OpenAIChatStreamingError: Codable {
    let error: ErrorMessage
    
    struct ErrorMessage: Codable {
        let message: String
    }
}
