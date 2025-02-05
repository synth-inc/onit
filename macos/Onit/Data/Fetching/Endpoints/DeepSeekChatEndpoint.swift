//
//  DeepSeekChatEndpoint.swift
//  Onit
//
//  Created by OpenHands on 2/13/25.
//

import Foundation

struct DeepSeekChatEndpoint: Endpoint {
    typealias Request = DeepSeekChatRequest
    typealias Response = DeepSeekChatResponse
    
    let messages: [DeepSeekChatMessage]
    let token: String
    let model: String
    
    var baseURL: URL {
        URL(string: "https://api.deepseek.com")!
    }
    
    var path: String { "/v1/chat/completions" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    
    var requestBody: DeepSeekChatRequest? {
        DeepSeekChatRequest(model: model, messages: messages)
    }
    
    var additionalHeaders: [String: String]? {
        ["Authorization": "Bearer \(token)"]
    }
}