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
    let tools: [Tool]
    let includeSearch: Bool?

    var path: String { "/v1/messages" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }

    var requestBody: AnthropicChatRequest? {
        var apiTools: [AnthropicChatTool] = tools.map { AnthropicChatTool(tool: $0) }
        if includeSearch == true {
            apiTools.append(AnthropicChatTool.search(maxUses: 5))
        }
        return AnthropicChatRequest(
            model: model,
            system: system,
            messages: messages,
            tools: apiTools,
            max_tokens: maxTokens,
            stream: false
        )
    }
    var additionalHeaders: [String: String]? {
        [
            "x-api-key": token ?? "",
            "anthropic-version": "2023-06-01",
        ]
    }
    var timeout: TimeInterval? { nil }
    
    func getContent(response: Response) -> String? {
        return response.content.first(where: { $0.type == "text" })?.text
    }
    
    func getToolResponse(response: Response) -> ChatResponse? {
        if let toolContent = response.content.first(where: { $0.type == "tool_use" }) {
            let argumentsString: String?
            if let input = toolContent.input {
                argumentsString = try? String(data: JSONEncoder().encode(input), encoding: .utf8)
            } else {
                argumentsString = nil
            }
            
            return ChatResponse(
                content: nil,
                functionName: toolContent.name,
                functionArguments: argumentsString
            )
        }
        
        if let textContent = response.content.first(where: { $0.type == "text" }),
           let text = textContent.text {
            return ChatResponse(
                content: text,
                functionName: nil,
                functionArguments: nil
            )
        }
        
        return nil
    }
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
    let tools: [AnthropicChatTool]
    let max_tokens: Int
    let stream: Bool
}

struct AnthropicChatTool: Codable {
    let type: String
    let name: String
    let description: String?
    let input_schema: AnthropicChatToolInputSchema?
    let maxUses: Int?
    
    enum CodingKeys: String, CodingKey {
        case type
        case name
        case description
        case input_schema
        case maxUses = "max_uses"
    }

    static func search(maxUses: Int) -> AnthropicChatTool {
        return AnthropicChatTool(type: "web_search_20250305", name: "web_search", maxUses: maxUses)
    }
    
    init(type: String, name: String, description: String? = nil, input_schema: AnthropicChatToolInputSchema? = nil, maxUses: Int? = nil) {
        self.type = type
        self.name = name
        self.description = description
        self.input_schema = input_schema
        self.maxUses = maxUses
    }
    
    init(tool: Tool) {
        self.type = "custom"
        self.name = tool.name
        self.description = tool.description
        self.input_schema = AnthropicChatToolInputSchema(toolParameters: tool.parameters)
        self.maxUses = nil
    }
}

struct AnthropicChatToolInputSchema: Codable {
    let type: String
    let properties: [String: AnthropicChatToolProperty]
    let required: [String]
    
    init(type: String, properties: [String: AnthropicChatToolProperty], required: [String]) {
        self.type = type
        self.properties = properties
        self.required = required
    }
    
    init(toolParameters: ToolParameters) {
        self.type = "object"
        self.required = toolParameters.required
        
        var convertedProperties: [String: AnthropicChatToolProperty] = [:]
        
        for (key, toolProperty) in toolParameters.properties {
            var items: [String: Any]? = nil
            
            if let toolPropertyItem = toolProperty.items {
                items = [
                    "type": toolPropertyItem.type
                ]
            }
            
            convertedProperties[key] = AnthropicChatToolProperty(
                type: toolProperty.type,
                description: toolProperty.description,
                items: items
            )
        }
        
        self.properties = convertedProperties
    }
}

struct AnthropicChatToolProperty: Codable {
    let type: String
    let description: String
    let items: AnyCodable?
    
    init(type: String, description: String, items: [String: Any]? = nil) {
        self.type = type
        self.description = description
        self.items = items.map(AnyCodable.init)
    }
    
    enum CodingKeys: String, CodingKey {
        case type, description, items
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

struct AnthropicChatResponse: Codable {
    let content: [AnthropicResponseContent]
    let stop_reason: String?
    
    struct AnthropicResponseContent: Codable {
        let type: String
        let text: String?
        let id: String?
        let name: String?
        let input: AnyCodable?
    }
}
