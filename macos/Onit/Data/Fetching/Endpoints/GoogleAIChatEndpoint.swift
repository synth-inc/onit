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
    let token: String?

    var path: String { "/v1beta:chatCompletions" }
    var getParams: [String: String]? { nil }

    var method: HTTPMethod { .post }
    var requestBody: GoogleAIChatRequest? {
        GoogleAIChatRequest(model:model, messages: messages, stream: true, n: 1)
    }

    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    
    func getContentFromSSE(event: EVEvent) throws -> String? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            return response.choices[0].delta.content
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(GoogleAIChatStreamingError.self, from: data)
        
        return response?.error.message
    }

    var timeout: TimeInterval? { nil }
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
    let stream: Bool
    let n : Int
}

struct GoogleAIChatResponse: Codable {
    let choices: [Choice]
    let created: Int
    let id: String
    let model: String
    let object: String
    
    struct Choice: Codable {
        let delta: Delta
        let index: Int
            
        enum CodingKeys: String, CodingKey {
            case delta
            case index
        }
    }
        
    struct Delta: Codable {
        let content: String?
        let role: String?
    }
}

struct GoogleAIChatStreamingError: Codable {
    struct Error: Codable {
        let message: String
    }
    
    let error: Error
}
