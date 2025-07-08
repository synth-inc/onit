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
    let model: String
    var token: String? { nil }
    let queryToken: String?
    let includeSearch: Bool?

    var path: String { "/v1beta/models/\(model):generateContent" }
    var getParams: [String: String]? {
        [
            "key": queryToken ?? ""
        ]
    }

    var method: HTTPMethod { .post }
    var requestBody: GoogleAIChatRequest? {
        var tools: [GoogleAIChatSearchTool] = []
        if includeSearch == true {
            tools.append(GoogleAIChatSearchTool())
        }
        return GoogleAIChatRequest(model: model, messages: messages, tools: tools, stream: false, n: 1)
    }

    var additionalHeaders: [String: String]? { [:] }
    var timeout: TimeInterval? { nil }
    
    func getContent(response: Response) -> String? {
        return response.choices.first?.message.content
    }
}

struct GoogleAIChatMessage: Codable {
    let role: String
    let content: GoogleAIChatContent
}

enum GoogleAIChatContent: Codable {
    case text(String)
    case multiContent([GoogleAIChatContentPart])

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
        } else if let parts = try? container.decode([GoogleAIChatContentPart].self) {
            self = .multiContent(parts)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid content format")
        }
    }
}

struct GoogleAIChatContentPart: Codable {
    let type: String
    let text: String?
    let image_url: ImageURL?

    struct ImageURL: Codable {
        let url: String
    }
}

struct GoogleAIChatRequest: Codable {
    let model: String
    let messages: [GoogleAIChatMessage]
    let tools: [GoogleAIChatSearchTool]
    let stream: Bool
    let n : Int
}

struct GoogleAIChatResponse: Codable {
    let choices: [Choice]
    let created: Int
    let model: String
    let object: String
    let usage: Usage

    struct Choice: Codable {
        let finishReason: String
        let index: Int
        let message: Message

        enum CodingKeys: String, CodingKey {
            case finishReason = "finish_reason"
            case index
            case message
        }
    }

    struct Message: Codable {
        let content: String
        let role: String
    }

    struct Usage: Codable {
        let completionTokens: Int
        let promptTokens: Int
        let totalTokens: Int

        enum CodingKeys: String, CodingKey {
            case completionTokens = "completion_tokens"
            case promptTokens = "prompt_tokens"
            case totalTokens = "total_tokens"
        }
    }
}

struct GoogleAIChatSearchTool: Codable {
    let googleSearch = GoogleSearch()

    struct GoogleSearch: Codable {}

    enum CodingKeys: String, CodingKey {
        case googleSearch = "google_search"
    }
}
