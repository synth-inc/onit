//
//  GoogleAIChatEndpoint.swift
//  Onit
//

import Foundation

struct GoogleAIChatEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://generativelanguage.googleapis.com")!
    
    typealias Request = GoogleAIChatRequest
    typealias Response = GoogleAIChatResponse
    
    let messages: [GoogleAIChatMessage]
    let model: String
    let token: String?
    
    var path: String { "/v1beta/models/\(model):generateContent" }
    var method: HTTPMethod { .post }
    var requestBody: GoogleAIChatRequest? {
        GoogleAIChatRequest(
            contents: messages
        )
    }
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token ?? "")"]
    }
}

struct GoogleAIChatMessage: Codable {
    let role: String
    let parts: [GoogleAIChatPart]
}

struct GoogleAIChatPart: Codable {
    let text: String?
    let inlineData: GoogleAIChatInlineData?
}

struct GoogleAIChatInlineData: Codable {
    let mimeType: String
    let data: String
}

struct GoogleAIChatRequest: Codable {
    let contents: [GoogleAIChatMessage]
}

struct GoogleAIChatResponse: Codable {
    let candidates: [Candidate]
    
    struct Candidate: Codable {
        let content: Content
        
        struct Content: Codable {
            let parts: [Part]
            
            struct Part: Codable {
                let text: String
            }
        }
    }
}