//
//  PerplexityChatStreamingEndpoint.swift
//  Onit
//
//  Created by timl on 3/3/25.
//

import Foundation
import EventSource

struct PerplexityChatStreamingEndpoint: StreamingEndpoint {
    var baseURL: URL = URL(string: "https://api.perplexity.ai")!

    typealias Request = PerplexityChatRequest
    typealias Response = PerplexityChatStreamingResponse

    let messages: [PerplexityChatMessage]
    let model: String
    let token: String?

    var path: String { "/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var requestBody: PerplexityChatRequest? {
        PerplexityChatRequest(model: model, messages: messages, stream: true)
    }
    var additionalHeaders: [String: String]? { nil }
    var timeout: TimeInterval? { nil }

    func getContentFromSSE(event: EVEvent) throws -> String? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            return response.choices.first?.delta.content
        }
        return nil
    }

    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(PerplexityChatStreamingError.self, from: data)
        return response?.error.message
    }
}

struct PerplexityChatStreamingResponse: Codable {
    let choices: [Choice]

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

struct PerplexityChatStreamingError: Codable {
    let error: ErrorMessage

    struct ErrorMessage: Codable {
        let message: String
    }
}

