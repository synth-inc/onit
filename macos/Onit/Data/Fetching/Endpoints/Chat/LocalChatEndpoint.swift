//
//  LocalChatEndpoint.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Defaults
import Foundation
import PhotosUI

struct LocalChatEndpoint: Endpoint {
    var additionalHeaders: [String : String]?
    
    typealias Request = LocalChatRequestJSON
    typealias Response = LocalChatResponseJSON

    let model: String?
    let messages: [LocalChatMessage]
    let tools: [Tool]
    var baseURL: URL {
        var url: URL!
        DispatchQueue.main.sync {
            url = Defaults[.localEndpointURL]
        }
        return url
    }

    var path: String { "/api/chat" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var token: String? { nil }
    var timeout: TimeInterval? {
        DispatchQueue.main.sync {
            return Defaults[.localRequestTimeout]
        }
    }
    var requestBody: LocalChatRequestJSON? {
        var options: LocalChatOptions?
        var keepAlive: String?
        
        DispatchQueue.main.sync {
            keepAlive = Defaults[.localKeepAlive]
            
            // Only create options if at least one parameter is set
            if Defaults[.localNumCtx] != nil || Defaults[.localTemperature] != nil ||
                Defaults[.localTopP] != nil || Defaults[.localTopK] != nil {
                options = LocalChatOptions(
                    num_ctx: Defaults[.localNumCtx],
                    temperature: Defaults[.localTemperature],
                    top_p: Defaults[.localTopP],
                    top_k: Defaults[.localTopK]
                )
            }
        }
        
        let ollamaTools = tools.map { LocalChatTool(tool: $0) }
        
        return LocalChatRequestJSON(
            model: model,
            messages: messages,
            stream: false,
            tools: ollamaTools.isEmpty ? nil : ollamaTools,
            keep_alive: keepAlive,
            options: options
        )
    }
    
    func getContent(response: Response) -> String? {
        return response.message.content
    }
    
    func getToolResponse(response: Response) -> ChatResponse? {
        if let toolCalls = response.message.tool_calls, let toolCall = toolCalls.first {
            return ChatResponse(
                content: nil,
                toolName: toolCall.function.name,
                toolArguments: toolCall.function.arguments
            )
        }
        
        if !response.message.content.isEmpty {
            return ChatResponse(
                content: response.message.content,
                toolName: nil,
                toolArguments: nil
            )
        }
        
        return nil
    }
}

// TODO change this to match the expected request
struct LocalChatRequestJSON: Codable {
    let model: String?
    let messages: [LocalChatMessage]
    var stream: Bool
    var tools: [LocalChatTool]?
    var keep_alive: String?
    var options: LocalChatOptions?
}

struct LocalChatOptions: Codable {
    var num_ctx: Int?
    var temperature: Double?
    var top_p: Double?
    var top_k: Int?
}

struct LocalChatMessage: Codable {
    let role: String
    let content: String
    let images: [String]?
}

struct LocalChatResponseJSON: Codable {
    let model: String
    let created_at: String
    let message: LocalChatMessageResponse
    let done_reason: String
    let done: Bool
    let total_duration: Int
    let load_duration: Int
    let prompt_eval_count: Int
    let prompt_eval_duration: Int
    let eval_count: Int
    let eval_duration: Int
}

struct LocalChatMessageResponse: Codable {
    let role: String
    let content: String
    let tool_calls: [LocalChatToolCall]?
}

struct LocalChatTool: Codable {
    let type: String
    let function: LocalChatToolFunction
    
    init(tool: Tool) {
        self.type = "function"
        self.function = LocalChatToolFunction(tool: tool)
    }
}

struct LocalChatToolFunction: Codable {
    let name: String
    let description: String
    let parameters: LocalChatToolParameters
    
    init(tool: Tool) {
        self.name = tool.name
        self.description = tool.description
        self.parameters = LocalChatToolParameters(toolParameters: tool.parameters)
    }
}

struct LocalChatToolParameters: Codable {
    let type: String
    let properties: [String: LocalChatToolProperty]
    let required: [String]
    
    init(toolParameters: ToolParameters) {
        self.type = "object"
        self.required = toolParameters.required
        
        var convertedProperties: [String: LocalChatToolProperty] = [:]
        
        for (key, toolProperty) in toolParameters.properties {
            var items: [String: Any]? = nil
            
            if let toolPropertyItem = toolProperty.items {
                items = [
                    "type": toolPropertyItem.type
                ]
            }
            
            convertedProperties[key] = LocalChatToolProperty(
                type: toolProperty.type,
                description: toolProperty.description,
                items: items
            )
        }
        
        self.properties = convertedProperties
    }
}

struct LocalChatToolProperty: Codable {
    let type: String
    let description: String
    let items: AnyCodable?
    
    enum CodingKeys: String, CodingKey {
        case type, description, items
    }
    
    init(type: String, description: String, items: [String: Any]? = nil) {
        self.type = type
        self.description = description
        self.items = items.map(AnyCodable.init)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(description, forKey: .description)
        
        if let items = items {
            try container.encode(items, forKey: .items)
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        description = try container.decode(String.self, forKey: .description)
        
        if let itemsData = try container.decodeIfPresent(AnyCodable.self, forKey: .items) {
            items = itemsData
        } else {
            items = nil
        }
    }
}

struct LocalChatToolCall: Codable {
    let function: LocalChatToolCallFunction
}

struct LocalChatToolCallFunction: Codable {
    let name: String?
    let arguments: String?
    
    enum CodingKeys: String, CodingKey {
        case name, arguments
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(arguments, forKey: .arguments)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decodeIfPresent(String.self, forKey: .name)

        if let argsValue = try container.decodeIfPresent(AnyCodable.self, forKey: .arguments) {
            let encoder = JSONEncoder()
            let data = try encoder.encode(argsValue)
            arguments = String(data: data, encoding: .utf8)
        } else {
            arguments = nil
        }
    }
}
