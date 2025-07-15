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
    let tools: [Tool]
    let searchTool: ChatSearchTool?
    
    var path: String { "/v1/responses" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: OpenAIChatRequest? {
        var apiTools: [OpenAIChatTool] = tools.map { OpenAIChatTool(tool: $0) }
        if let searchTool = searchTool, let type = searchTool.type {
            apiTools.append(OpenAIChatTool.search(type: type))
        }
        return OpenAIChatRequest(model: model, input: messages, tools: apiTools, stream: true)
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    
    var timeout: TimeInterval? { nil }
    
    func getContentFromSSE(event: EVEvent) throws -> StreamingEndpointResponse? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            if response.type == "response.output_text.delta" {
                return StreamingEndpointResponse(content: response.delta, toolName: nil, toolArguments: nil)
            }
            if response.type == "response.completed" {
                if let toolCall = response.response?.output?.first {
                    return StreamingEndpointResponse(content: nil,
                                                     toolName: toolCall.name,
                                                     toolArguments: toolCall.arguments)
                }
            }
            return nil
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(OpenAIChatStreamingError.self, from: data)
        
        return response?.error.message
    }
}

struct OpenAIChatStreamingResponse: Codable {
    let type: String?
    let delta: String?
    let response: OpenAIChatStreamingCompletedResponse?
}

struct OpenAIChatStreamingCompletedResponse: Codable {
    let output: [OpenAIChatStreamingFunctionCall]?
}

struct OpenAIChatStreamingFunctionCall: Codable {
    let type: String?
    let status: String?
    let arguments: String?
    let name: String?
}

struct OpenAIChatStreamingError: Codable {
    let error: ErrorMessage
    
    struct ErrorMessage: Codable {
        let message: String
    }
}
