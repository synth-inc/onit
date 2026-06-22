//
//  CerebrasChatStreamingEndpoint.swift
//  Onit
//
//  Created by Kévin Naudin on 12/01/2025.
//

import EventSource
import Foundation

struct CerebrasChatStreamingEndpoint: StreamingEndpoint {
    typealias Request = CerebrasChatRequest
    typealias Response = CerebrasChatStreamingResponse

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
        CerebrasChatRequest(model: model, messages: messages, stream: true)
    }

    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
    var timeout: TimeInterval? { nil }

    func getContentFromSSE(event: EVEvent) throws -> StreamingEndpointResponse? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)

            if let content = response.choices.first?.delta.content {
                return StreamingEndpointResponse(content: content, toolName: nil, toolArguments: nil)
            }
        }

        return nil
    }

    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(CerebrasChatStreamingError.self, from: data)

        return response?.error.message
    }
}

struct CerebrasChatStreamingResponse: Codable {
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

struct CerebrasChatStreamingError: Codable {
    let error: ErrorMessage

    struct ErrorMessage: Codable {
        let message: String
    }
}
