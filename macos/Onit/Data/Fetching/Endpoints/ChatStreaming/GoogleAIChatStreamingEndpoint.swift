//
//  GoogleAIChatStreamingEndpoint.swift
//  Onit
//

import Foundation
import EventSource

struct GoogleAIChatStreamingEndpoint: StreamingEndpoint {
    var baseURL: URL = URL(string: "https://generativelanguage.googleapis.com")!
    
    typealias Request = GoogleAIChatRequest
    typealias Response = GoogleAIChatResponse
    
    let messages: [GoogleAIChatMessage]
    let system: String?
    let model: String
    // Doing this so the token doesn't get added as a header
    var token: String? { nil }
    let queryToken: String?
    let includeSearch: Bool?
    
    var path: String { "/v1beta/models/\(model):streamGenerateContent" }
    var getParams: [String: String]? {
        [
            "key": queryToken ?? "",
            "alt": "sse"
        ]
    }
    var method: HTTPMethod { .post }
    var requestBody: GoogleAIChatRequest? {
        var systemInstruction: GoogleAIChatSystemInstruction?
        if let system = system {
            systemInstruction = GoogleAIChatSystemInstruction(parts: [GoogleAIChatPart(text: system, inlineData: nil)])
        }
        var tools: [GoogleAIChatSearchTool] = []
        if includeSearch == true {
            tools.append(GoogleAIChatSearchTool())
        }
        return GoogleAIChatRequest(systemInstruction: systemInstruction, contents: messages, tools: tools)
    }
    
    var additionalHeaders: [String: String]? { [:] }
    
    var timeout: TimeInterval? { nil }
    
    func getContentFromSSE(event: EVEvent) throws -> StreamingEndpointResponse? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            if let part = response.candidates.first?.content.parts.first(where: { $0.text != nil }) {
                return StreamingEndpointResponse(content: part.text, toolName: nil, toolArguments: nil)
            }
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(GoogleAIChatStreamingError.self, from: data)
        
        return response?.error.message
    }
}

struct GoogleAIChatStreamingError: Codable {
    let error: Error

    struct Error: Codable {
        let message: String
    }
}
