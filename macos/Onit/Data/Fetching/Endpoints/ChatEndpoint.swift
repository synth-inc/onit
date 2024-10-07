//
//  ChatEndpoint.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension FetchingClient {
    func chat(_ text: String, input: Input?) async throws -> String {
        let endpoint = ChatEndpoint(instructions: text, input: input)
        let response = try await execute(endpoint)
        return response.output
    }
}

struct ChatEndpoint: Endpoint {
    typealias Request = ChatRequestJSON
    typealias Response = ProcessResponse

    let instructions: String
    let input: Input?

    var path: String { "/process" }
    var method: HTTPMethod { .post }
    var token: String? { Token.token }
    var requestBody: ChatRequestJSON? { ChatRequestJSON(instructions: instructions, input: input) }
    var additionalHeaders: [String: String]? { nil }
}

struct ChatRequestJSON: Codable {
    let instructions: String
    let input: Input?
}

struct ProcessResponse: Codable {
    let output: String
}
