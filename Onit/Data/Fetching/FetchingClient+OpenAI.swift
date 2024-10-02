//
//  FetchingClient+OpenAI.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation

extension FetchingClient {
//    func getResponse(from input: String) async throws -> String {
//        let request = OpenAIRequest(input: input)
//        return try await fetch(request: request)
//    }
}

extension FetchingClient {
//    func fetch<Response>(request: FetchingRequest) async throws -> Response {
//        let url = url
//    }
}

protocol FetchingRequest {
    var baseURL: URL { get }
    var endpoint: String { get }
}

struct OpenAIEndpoint: FetchingRequest {
    var model: OpenAIModel = .gpt4o

    var endpoint: String {
        "/chat/completions"
    }

    var baseURL: URL {
        .init(string: "https://api.openai.com/v1/models")!
    }
}

enum OpenAIModel: String {
    case gpt3_5 = "gpt-3.5-turbo"
    case gpt4 = "gpt-4"
    case gpt4o = "gpt-4o"
    case gpt4oMini = "gpt-4o-mini"
}
