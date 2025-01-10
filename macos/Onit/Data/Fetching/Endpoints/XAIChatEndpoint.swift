//
//  XAIChatEndpoint.swift
//  Onit
//

import Foundation

struct XAIChatEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://api.x.ai")!
    
    typealias Request = XAIChatRequest
    typealias Response = XAIChatResponse
    
    let messages: [XAIChatMessage]
    let model: String
    let token: String?
    
    var path: String { "/v1/chat/completions" }
    var method: HTTPMethod { .post }
    var requestBody: XAIChatRequest? {
        XAIChatRequest(
            model: model,
            messages: messages
        )
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
}

struct XAIChatMessage: Codable {
    let role: String
    let content: XAIChatContent
}

enum XAIChatContent: Codable {
    case text(String)
    case multiContent([XAIChatContentPart])
    
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
        } else if let parts = try? container.decode([XAIChatContentPart].self) {
            self = .multiContent(parts)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid content format")
        }
    }
}

struct XAIChatContentPart: Codable {
    let type: String
    let text: String?
    let image: ImageData?
    
    struct ImageData: Codable {
        let url: String?
        let base64: String?
    }
}

struct XAIChatRequest: Codable {
    let model: String
    let messages: [XAIChatMessage]
    let stream: Bool = true
}

struct XAIChatResponse: Codable {
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
