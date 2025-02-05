//
//  DeepSeekChatResponse.swift
//  Onit
//
//  Created by OpenHands on 2/13/25.
//

import Foundation

struct DeepSeekChatResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
        
        struct Message: Codable {
            let content: String
        }
    }
}