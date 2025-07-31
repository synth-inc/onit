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
    let supportsToolCalling: Bool
    let tools: [Tool]
    let searchTool: ChatSearchTool?
    
    private let toolAccumulator = StreamToolAccumulator()
    
    var path: String { "/v1/messages" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    
    var requestBody: AnthropicChatRequest? {
        var apiTools: [AnthropicChatTool] = []
        if supportsToolCalling {
            apiTools = tools.map { AnthropicChatTool(tool: $0) }
            if let searchTool = searchTool,
               let type = searchTool.type,
               let name = searchTool.name,
               let maxUses = searchTool.maxUses
            {
                apiTools.append(AnthropicChatTool.search(type: type, name: name, maxUses: maxUses))
            }
        }
        return AnthropicChatRequest(
            model: model,
            system: system,
            messages: messages,
            tools: apiTools,
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
    
    func getContentFromSSE(event: EVEvent) throws -> StreamingEndpointResponse? {
        
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            if response.contentBlock?.type == "server_tool_use" {
                return StreamingEndpointResponse(content: "\n\n...\n\n", toolName: nil, toolArguments: nil)
            }
            
            if let content = response.delta?.text {
                return StreamingEndpointResponse(content: content, toolName: nil, toolArguments: nil)
            }
            
            if response.type == "content_block_start" && response.contentBlock?.type == "tool_use" {
                if let toolName = response.contentBlock?.name {
                    return toolAccumulator.startTool(name: toolName)
                }
            }
            
            if response.type == "content_block_delta" && response.delta?.type == "input_json_delta" {
                if toolAccumulator.hasActiveTool(), let partialJson = response.delta?.partialJson {
                    return toolAccumulator.addArguments(partialJson)
                }
            }
            
            if response.type == "message_delta" && response.delta?.stopReason == "tool_use" {
                if toolAccumulator.hasActiveTool() {
                    return toolAccumulator.finishTool()
                }
            }
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
        let stopReason: String?
        
        enum CodingKeys: String, CodingKey {
            case type
            case text
            case partialJson = "partial_json"
            case stopReason = "stop_reason"
        }
    }

    struct ContentBlock: Codable {
        let type: String?
        let name: String?
        let input: AnyCodable?
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
