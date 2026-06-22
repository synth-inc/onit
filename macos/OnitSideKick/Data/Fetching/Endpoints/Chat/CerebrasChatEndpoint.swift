//
//  CerebrasChatEndpoint.swift
//  Onit
//
//  Created by Kévin Naudin on 12/01/2025.
//

import Foundation

struct CerebrasChatEndpoint: Endpoint {
    typealias Request = CerebrasChatRequest
    typealias Response = CerebrasChatResponse

    let messages: [CerebrasChatMessage]
    let model: String
    let token: String?

    var baseURL: URL {
        URL(string: "https://api.cerebras.ai")!
    }

    var path: String { "/v1/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }

    var requestBody: CerebrasChatRequest? {
        CerebrasChatRequest(model: model, messages: messages, stream: false)
    }

    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    var timeout: TimeInterval? { nil }

    func getContent(response: Response) -> String? {
        return response.choices.first?.message.content
    }
}

struct CerebrasChatRequest: Codable {
    let model: String
    let messages: [CerebrasChatMessage]
    let stream: Bool
}

struct CerebrasChatMessage: Codable {
    let role: String
    let content: CerebrasChatContent
}

enum CerebrasChatContent: Codable {
    case text(String)

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let str):
            try container.encode(str)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            self = .text(str)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Invalid content format")
        }
    }
}

struct CerebrasChatResponse: Codable {
    let choices: [Choice]

    struct Choice: Codable {
        let message: Message

        struct Message: Codable {
            let content: String
        }
    }
}
