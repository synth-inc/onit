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

    var path: String { "/v1/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: OpenAIChatRequest? {
        OpenAIChatRequest(model: model, messages: messages, stream: false)
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    var timeout: TimeInterval? { nil }
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
    let image_url: ImageURL?

    struct ImageURL: Codable {
        let url: String
    }
}

struct OpenAIChatRequest: Codable {
    let model: String
    let messages: [OpenAIChatMessage]
    let stream: Bool
}

struct OpenAIChatResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}
