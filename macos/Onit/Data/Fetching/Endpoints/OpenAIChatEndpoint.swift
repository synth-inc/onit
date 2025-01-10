//
//  OpenAIChatEndpoint.swift
//  Onit
//

import Foundation

struct OpenAIChatEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.openai.com")!
    
    typealias Request = OpenAIChatRequest
    typealias Response = OpenAIChatResponse
    
    let messages: [OpenAIChatMessage]
    let model: String
    let token: String?
    
    var path: String { "/v1/chat/completions" }
    var method: HTTPMethod { .post }
    var requestBody: OpenAIChatRequest? {
        OpenAIChatRequest(model: model, messages: messages)
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
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
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid content format")
        }
    }
}

struct OpenAIChatContentPart: Codable {
    let type: String
    let text: String?
    let image_url: ImageURL?
    
    struct ImageURL: Codable {
        let url: String
    }
}

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIChatMessage]
    let stream: Bool = true
}

struct OpenAIChatResponse: Codable {
    let choices: [Choice]
    let created: Int
    let id: String
    let model: String
    let object: String
    
    struct Choice: Codable {
        let delta: Delta
        let index: Int
        let finishReason: String?
        
        enum CodingKeys: String, CodingKey {
            case delta
            case index
            case finishReason = "finish_reason"
        }
    }
    
    struct Delta: Codable {
        let content: String?
        let role: String?
    }
}
