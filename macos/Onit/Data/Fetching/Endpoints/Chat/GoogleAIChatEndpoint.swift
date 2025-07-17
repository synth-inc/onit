//
//  GoogleAIChatEndpoint.swift
//  Onit
//

import Foundation
import EventSource

struct GoogleAIChatEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://generativelanguage.googleapis.com")!

    typealias Request = GoogleAIChatRequest
    typealias Response = GoogleAIChatResponse

    let messages: [GoogleAIChatMessage]
    let system: String?
    let model: String
    // Doing this so the token doesn't get added as a header
    var token: String? { nil }
    let queryToken: String?
    let supportsToolCalling: Bool
    let tools: [Tool]
    let includeSearch: Bool?

    var path: String { "/v1beta/models/\(model):generateContent" }
    var getParams: [String: String]? {
        [
            "key": queryToken ?? ""
        ]
    }

    var method: HTTPMethod { .post }
    var requestBody: GoogleAIChatRequest? {
        var systemInstruction: GoogleAIChatSystemInstruction?
        if let system = system {
            systemInstruction = GoogleAIChatSystemInstruction(parts: [GoogleAIChatPart(text: system, inlineData: nil, functionCall: nil)])
        }
        var apiTools: [GoogleAIChatTool] = []
        if supportsToolCalling {
            if !tools.isEmpty {
                apiTools.append(.functionDeclarations(tools.map { GoogleAIChatToolDeclaration(tool: $0) }))
            }
            if includeSearch == true {
                apiTools.append(.googleSearch(GoogleAIChatTool.GoogleSearch()))
            }
        }
        return GoogleAIChatRequest(systemInstruction: systemInstruction, contents: messages, tools: apiTools)
    }

    var additionalHeaders: [String: String]? { [:] }
    var timeout: TimeInterval? { nil }
    
    func getContent(response: Response) -> String? {
        let part = response.candidates.first?.content.parts.first { $0.text != nil }
        return part?.text
    }

    func getToolResponse(response: Response) -> ChatResponse? {
        let part = response.candidates.first?.content.parts.first { $0.functionCall != nil }

        if let functionCall = part?.functionCall {
            return ChatResponse(content: part?.text, toolName: functionCall.name, toolArguments: functionCall.args)
        }

        return nil
    }
}

struct GoogleAIChatSystemInstruction: Codable {
    let parts: [GoogleAIChatPart]
}

struct GoogleAIChatMessage: Codable {
    let role: String
    let parts: [GoogleAIChatPart]
}

struct GoogleAIChatPart: Codable {
    let text: String?
    let inlineData: InlineData?
    let functionCall: FunctionCall?

    struct InlineData: Codable {
        let mimeType: String
        let data: String
    }

    struct FunctionCall: Codable {
        let name: String?
        let args: String?

        enum CodingKeys: String, CodingKey {
            case name, args
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            name = try container.decodeIfPresent(String.self, forKey: .name)

            // Decode args as any JSON value and convert to string
            if let argsValue = try container.decodeIfPresent(AnyCodable.self, forKey: .args) {
                let encoder = JSONEncoder()
                let data = try encoder.encode(argsValue)
                args = String(data: data, encoding: .utf8)
            } else {
                args = nil
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encodeIfPresent(name, forKey: .name)
            try container.encodeIfPresent(args, forKey: .args)
        }
    }
}

struct GoogleAIChatRequest: Codable {
    let systemInstruction: GoogleAIChatSystemInstruction?
    let contents: [GoogleAIChatMessage]
    let tools: [GoogleAIChatTool]?
}

struct GoogleAIChatResponse: Codable {
    let candidates: [GoogleAIChatCandidate]

    struct GoogleAIChatCandidate: Codable {
        let content: GoogleAIChatMessage
    }
}

enum GoogleAIChatTool: Codable {
    case googleSearch(GoogleSearch)
    case functionDeclarations([GoogleAIChatToolDeclaration])

    struct GoogleSearch: Codable {}

    enum CodingKeys: String, CodingKey {
        case googleSearch = "google_search"
        case functionDeclarations = "function_declarations"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .googleSearch(let googleSearch):
            try container.encode(googleSearch, forKey: .googleSearch)
        case .functionDeclarations(let declarations):
            try container.encode(declarations, forKey: .functionDeclarations)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let googleSearch = try? container.decode(GoogleSearch.self, forKey: .googleSearch) {
            self = .googleSearch(googleSearch)
        } else if let declarations = try? container.decode([GoogleAIChatToolDeclaration].self, forKey: .functionDeclarations) {
            self = .functionDeclarations(declarations)
        } else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unable to decode GoogleAIChatTool"))
        }
    }
}

struct GoogleAIChatToolDeclaration: Codable {
    let name: String?
    let description: String?
    let parameters: GoogleAIChatToolParameters?

    init(type: String,
         name: String? = nil,
         description: String? = nil,
         parameters: GoogleAIChatToolParameters? = nil) {
        self.name = name
        self.description = description
        self.parameters = parameters
    }

    init(tool: Tool) {
        self.name = tool.name
        self.description = tool.description
        self.parameters = .init(toolParameters: tool.parameters)
    }
}

struct GoogleAIChatToolParameters: Codable {
    let type: String
    let properties: [String: GoogleAIChatToolProperty]
    let required: [String]

    init(type: String, properties: [String : GoogleAIChatToolProperty], required: [String]) {
        self.type = type
        self.properties = properties
        self.required = required
    }

    init(toolParameters: ToolParameters) {
        self.type = "object"
        self.required = toolParameters.required

        var convertedProperties: [String: GoogleAIChatToolProperty] = [:]

        for (key, toolProperty) in toolParameters.properties {
            var items: [String: Any]? = nil

            if let toolPropertyItem = toolProperty.items {
                items = [
                    "type": toolPropertyItem.type
                ]
            }

            convertedProperties[key] = GoogleAIChatToolProperty(
                type: toolProperty.type,
                description: toolProperty.description,
                items: items
            )
        }

        self.properties = convertedProperties
    }
}

struct GoogleAIChatToolProperty: Codable {
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
