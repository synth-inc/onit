//
//  ChatEndpoint.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension FetchingClient {
    func chat(_ text: String, input: Input?, model: GPTModel?, files: [URL], images: [URL]) async throws -> String {
        let endpoint = ChatEndpoint(instructions: text, input: input, model: model, images: images)
        let response = try await {
            if files.isEmpty {
                try await execute(endpoint)
            } else {
                try await executeMultipart(endpoint, files: files)
            }
        }()
        return response.output
    }
}

struct ChatEndpoint: Endpoint {
    typealias Request = ChatRequestJSON
    typealias Response = ProcessResponse

    let instructions: String
    let input: Input?
    let model: GPTModel?
    let images: [URL]

    var path: String { "/process" }
    var method: HTTPMethod { .post }
    var token: String? { Token.token }
    var requestBody: ChatRequestJSON? {
        ChatRequestJSON(instructions: instructions, input: input, model: model, images: images)
    }
    var additionalHeaders: [String: String]? { nil }
}

struct ChatRequestJSON: Codable {
    let instructions: String
    let input: Input?
    let model: GPTModel?
    let images: [URL]
}

struct ProcessResponse: Codable {
    let output: String
}
