//
//  OnitChatStreamingEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/28/25.
//

import Foundation
import EventSource

struct OnitChatStreamingEndpoint: StreamingEndpoint {
    typealias Request = OnitChatRequest

    typealias Response = OnitChatStreamingResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/chat/message" }

    var getParams: [String: String]? { nil }

    var method: HTTPMethod { .post }

    var token: String? { TokenManager.token }

    let model: AIModel
    let messages: [OnitChatMessage]
    let tools: [Tool]
    let includeSearch: Bool?
    
    private let streamToolAccumulator = StreamToolAccumulator()

    var requestBody: OnitChatRequest? {
        return OnitChatRequest(model: model.id, messages: messages, tools: tools, includeSearch: includeSearch)
    }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }

    func getContentFromSSE(event: EVEvent) throws -> StreamingEndpointResponse? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            var endpointResponse: StreamingEndpointResponse?
            
            if model.provider.isStreamingPartialTool {
                if let toolName = response.toolName, !streamToolAccumulator.hasActiveTool() {
                    endpointResponse = streamToolAccumulator.startTool(name: toolName)
                }
                
                if let toolArguments = response.toolArguments, streamToolAccumulator.hasActiveTool() {
                    endpointResponse = streamToolAccumulator.addArguments(toolArguments)
                }
                
                if response.toolComplete == true, streamToolAccumulator.hasActiveTool() {
                    endpointResponse = streamToolAccumulator.finishTool()
                }
                
                if let content = response.content, !content.isEmpty {
                    endpointResponse = endpointResponse ?? StreamingEndpointResponse(content: nil, toolName: nil, toolArguments: nil)
                    endpointResponse?.content = response.content
                }
                
                return endpointResponse
            } else {
                return StreamingEndpointResponse(content: response.content, toolName: response.toolName, toolArguments: response.toolArguments)
            }
        }
        return nil
    }

    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(OnitChatStreamingError.self, from: data)
        return response?.error
    }
}

struct OnitChatRequest: Encodable {
    let model: String
    let messages: [OnitChatMessage]
    let tools: [Tool]
    let includeSearch: Bool?
}

struct OnitChatMessage: Codable {
    let role: String
    let content: [OnitContent]
}

struct OnitContent: Codable {
    let type: String
    let text: String?
    let source: OnitImageSource?
}

struct OnitImageSource: Codable {
    let mimeType: String
    let data: String
}

struct OnitChatStreamingResponse: Codable {
    let content: String?
    let toolName: String?
    let toolArguments: String?
    let toolComplete: Bool?
}

struct OnitChatStreamingError: Codable {
    let error: String
}
