//
//  OnitChatStreamingEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/28/25.
//

import Foundation
import EventSource

struct OnitChatStreamingEndpoint: StreamingEndpoint {
    typealias Request = OnitChatRequest

    typealias Response = OnitChatStreamingResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/chat/message" }

    var getParams: [String: String]? { nil }

    var method: HTTPMethod { .post }

    var token: String? { TokenManager.token }

    let model: String

    let messages: [OnitChatMessage]

    var requestBody: OnitChatRequest? {
        OnitChatRequest(model: model, messages: messages)
    }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }

    func getContentFromSSE(event: EVEvent) throws -> String? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            return response.content
        }
        return nil
    }

    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(OnitChatStreamingError.self, from: data)
        return response?.error
    }
}

struct OnitChatRequest: Codable {
    let model: String
    let messages: [OnitChatMessage]
}

struct OnitChatMessage: Codable {
    let role: String
    let content: [OnitContent]
}

struct OnitContent: Codable {
    let type: String
    let text: String?
    let source: OnitImageSource?
}

struct OnitImageSource: Codable {
    let mimeType: String
    let data: String
}

struct OnitChatStreamingResponse: Codable {
    let content: String
}

struct OnitChatStreamingError: Codable {
    let error: String
}
