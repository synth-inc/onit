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

    func getContentFromSSE(event: EVEvent) throws -> StreamingEndpointResponse? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            let content = response.choices.first?.delta.content

            guard var content = content else {
                return StreamingEndpointResponse(content: nil, toolName: nil, toolArguments: nil)
            }
            
            guard let citations = response.citations, !citations.isEmpty else {
                return StreamingEndpointResponse(content: content, toolName: nil, toolArguments: nil)
            }
            
            for (index, citation) in citations.enumerated() {
                let realIndex = index + 1
                let citation = "[CITATION, \(realIndex), \(citation)]"
                content = content.replacingOccurrences(of: "[\(realIndex)]", with: citation)
            }
            
            return StreamingEndpointResponse(content: content, toolName: nil, toolArguments: nil)
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
    let citations: [String]?

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

