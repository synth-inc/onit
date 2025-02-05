//
//  DeepSeekChatEndpoint.swift
//  Onit
//
//  Created by OpenHands on 2/13/25.
//

import Foundation

struct DeepSeekChatEndpoint: Endpoint {
    typealias Request = DeepSeekChatRequest
    typealias Response = DeepSeekChatResponse
    
    let messages: [DeepSeekChatMessage]
    let token: String?
    let model: String
    
    var baseURL: URL {
        URL(string: "https://api.deepseek.com")!
    }
    
    var path: String { "/v1/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    
    var requestBody: DeepSeekChatRequest? {
        DeepSeekChatRequest(model: model, messages: messages)
    }
    
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
}

struct DeepSeekChatRequest: Codable {
    let model: String
    let messages: [DeepSeekChatMessage]
}

struct DeepSeekChatMessage: Codable {
    let role: String
    let content: DeepSeekChatContent
}

enum DeepSeekChatContent: Codable {
    case text(String)
    case multiContent([DeepSeekChatContentPart])
    
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
        } else if let parts = try? container.decode([DeepSeekChatContentPart].self) {
            self = .multiContent(parts)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid content format")
        }
    }
}

struct DeepSeekChatContentPart: Codable {
    let type: String
    let text: String?
    let image_url: ImageURL?
    
    struct ImageURL: Codable {
        let url: String
    }
}

struct DeepSeekChatResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}
