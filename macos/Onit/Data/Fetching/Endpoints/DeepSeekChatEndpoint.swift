//
//  DeepSeekChatEndpoint.swift
//  Onit
//
//  Created by OpenHands on 2/13/25.
//

import Foundation

struct DeepSeekChatEndpoint: Endpoint {
    typealias Response = DeepSeekChatResponse
    let messages: [OpenAIChatMessage]
    let model: String
    let token: String
    
    var baseURL: URL {
        URL(string: "https://api.deepseek.com/v1/chat/completions")!
    }
    
    var method: String {
        "POST"
    }
    
    var headers: [String: String] {
        [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(token)"
        ]
    }
    
    var body: Data? {
        let parameters: [String: Any] = [
            "model": model,
            "messages": messages.map { $0.dictionary },
            "stream": true
        ]
        
        return try? JSONSerialization.data(withJSONObject: parameters)
    }
    
    var responseType: EndpointResponseType {
        .streamedJSON
    }
}