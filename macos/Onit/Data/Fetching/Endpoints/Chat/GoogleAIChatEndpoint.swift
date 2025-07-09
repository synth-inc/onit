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
    let system: String?
    let model: String
    // Doing this so the token doesn't get added as a header
    var token: String? { nil }
    let queryToken: String?
    let includeSearch: Bool?

    var path: String { "/v1beta/models/\(model):generateContent" }
    var getParams: [String: String]? {
        [
            "key": queryToken ?? ""
        ]
    }

    var method: HTTPMethod { .post }
    var requestBody: GoogleAIChatRequest? {
        var systemInstruction: GoogleAIChatSystemInstruction?
        if let system = system {
            systemInstruction = GoogleAIChatSystemInstruction(parts: [GoogleAIChatPart(text: system, inlineData: nil)])
        }
        var tools: [GoogleAIChatSearchTool] = []
        if includeSearch == true {
            tools.append(GoogleAIChatSearchTool())
        }
        return GoogleAIChatRequest(systemInstruction: systemInstruction, contents: messages, tools: tools)
    }

    var additionalHeaders: [String: String]? { [:] }
    var timeout: TimeInterval? { nil }
    
    func getContent(response: Response) -> String? {
        let part = response.candidates.first?.content.parts.first { $0.text != nil }
        return part?.text
    }
}

struct GoogleAIChatSystemInstruction: Codable {
    let parts: [GoogleAIChatPart]
}

struct GoogleAIChatMessage: Codable {
    let role: String
    let parts: [GoogleAIChatPart]
}

struct GoogleAIChatPart: Codable {
    let text: String?
    let inlineData: InlineData?

    struct InlineData: Codable {
        let mimeType: String
        let data: String
    }
}

struct GoogleAIChatRequest: Codable {
    let systemInstruction: GoogleAIChatSystemInstruction?
    let contents: [GoogleAIChatMessage]
    let tools: [GoogleAIChatSearchTool]?
}

struct GoogleAIChatResponse: Codable {
    let candidates: [GoogleAIChatCandidate]

    struct GoogleAIChatCandidate: Codable {
        let content: GoogleAIChatMessage
    }
}

struct GoogleAIChatSearchTool: Codable {
    let googleSearch = GoogleSearch()

    struct GoogleSearch: Codable {}

    enum CodingKeys: String, CodingKey {
        case googleSearch = "google_search"
    }
}
