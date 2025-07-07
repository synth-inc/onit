//
//  OpenAIChatEndpoint.swift
//  Onit
//

import Foundation
import EventSource

struct OpenAIChatEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.openai.com")!

    typealias Request = OpenAIChatRequest
    typealias Response = OpenAIChatResponse

    let messages: [OpenAIChatMessage]
    let token: String?
    let model: String
    let tools: [Tool]
    let includeSearch: Bool?

    var path: String { "/v1/responses" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: OpenAIChatRequest? {
        var apiTools: [OpenAIChatTool] = tools.map { OpenAIChatTool(tool: $0) }
        if includeSearch == true {
            apiTools.append(OpenAIChatTool.search())
        }
        return OpenAIChatRequest(model: model, input: messages, tools: apiTools, stream: false)
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    var timeout: TimeInterval? { nil }
    
    func getContent(response: Response) -> String? {
        return response.delta
    }
    
    func getToolResponse(response: Response) -> ChatResponse? {
        if let functionCall = response.output?.first(where: { $0.type == "function_call" }) {
            return ChatResponse(
                content: nil,
                functionName: functionCall.name,
                functionArguments: functionCall.arguments
            )
        }
        
        if let content = response.delta {
            return ChatResponse(
                content: content,
                functionName: nil,
                functionArguments: nil
            )
        }
        
        return nil
    }
}

struct OpenAIChatMessage: Codable {
    let role: String
    let content: OpenAIChatContent
}

enum OpenAIChatContent: Codable {
    case text(String)
    case multiContent([OpenAIChatContentPart])

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let str):
            try container.encode(str)
        case .multiContent(let parts):
            try container.encode(parts)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .text(str)
        } else if let parts = try? container.decode([OpenAIChatContentPart].self) {
            self = .multiContent(parts)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid content format")
        }
    }
}

struct OpenAIChatContentPart: Codable {
    let type: String
    let text: String?
    let image_url: String?
}

struct OpenAIChatRequest: Codable {
    let model: String
    let input: [OpenAIChatMessage]
    let tools: [OpenAIChatTool]
    let stream: Bool
}

struct OpenAIChatTool: Codable {
    let type: String
    let name: String?
    let description: String?
    let parameters: OpenAIChatToolParameters?

    static func search() -> OpenAIChatTool {
        return OpenAIChatTool(type: "web_search_preview")
    }
    
    init(type: String,
         name: String? = nil,
         description: String? = nil,
         parameters: OpenAIChatToolParameters? = nil) {
        self.type = type
        self.name = name
        self.description = description
        self.parameters = parameters
    }
    
    init(tool: Tool) {
        self.type = "function"
        self.name = tool.name
        self.description = tool.description
        self.parameters = .init(toolParameters: tool.parameters)
    }
}

struct OpenAIChatToolParameters: Codable {
    let type: String
    let properties: [String: OpenAIChatToolProperty]
    let required: [String]
    
    init(type: String, properties: [String : OpenAIChatToolProperty], required: [String]) {
        self.type = type
        self.properties = properties
        self.required = required
    }
    
    init(toolParameters: ToolParameters) {
        self.type = "object"
        self.required = toolParameters.required
        
        var convertedProperties: [String: OpenAIChatToolProperty] = [:]
        
        for (key, toolProperty) in toolParameters.properties {
            var items: [String: Any]? = nil
            
            if let toolPropertyItem = toolProperty.items {
                items = [
                    "type": toolPropertyItem.type
                ]
            }
            
            convertedProperties[key] = OpenAIChatToolProperty(
                type: toolProperty.type,
                description: toolProperty.description,
                items: items
            )
        }
        
        self.properties = convertedProperties
    }
}

struct OpenAIChatToolProperty: Codable {
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

struct OpenAIChatResponse: Codable {
    let delta: String?
    let output: [OpenAIChatResponseOutput]?
    
    struct OpenAIChatResponseOutput: Codable {
        let type: String?
        let name: String?
        let arguments: String?
        let status: String?
    }
}
