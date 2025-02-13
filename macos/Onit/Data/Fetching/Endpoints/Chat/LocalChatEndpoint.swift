//
//  LocalChatEndpoint.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Defaults
import Foundation
import PhotosUI

struct LocalChatEndpoint: Endpoint {
    var additionalHeaders: [String : String]?
    
    typealias Request = LocalChatRequestJSON
    typealias Response = LocalChatResponseJSON

    let model: String?
    let messages: [LocalChatMessage]
    let keepAlive: String?
    let options: LocalChatOptions
    
    var baseURL: URL {
        var url: URL!
        DispatchQueue.main.sync {
            url = Defaults[.localEndpointURL]
        }
        return url
    }

    var path: String { "/api/chat" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var token: String? { nil }
    var timeout: TimeInterval? {
        DispatchQueue.main.sync {
            return Defaults[.localRequestTimeout]
        }
    }
    var requestBody: LocalChatRequestJSON? {
        // Only create options if at least one parameter is set
        let newOptions: LocalChatOptions?
        if options.isEmpty {
            newOptions = nil
        } else {
            newOptions = options
        }
        
        return LocalChatRequestJSON(
            model: model,
            messages: messages,
            stream: false,
            keep_alive: keepAlive,
            options: newOptions
        )
    }
}

// TODO change this to match the expected request
struct LocalChatRequestJSON: Codable {
    let model: String?
    let messages: [LocalChatMessage]
    var stream: Bool
    var keep_alive: String?
    var options: LocalChatOptions?
}

struct LocalChatOptions: Codable {
    var num_ctx: Int?
    var temperature: Double?
    var top_p: Double?
    var top_k: Int?
    
    var isEmpty: Bool {
        num_ctx == nil && temperature == nil &&
        top_p == nil && top_k == nil
    }
}

struct LocalChatMessage: Codable {
    let role: String
    let content: String
    let images: [String]?
}

struct LocalChatResponseJSON: Codable {
    let model: String
    let created_at: String
    let message: LocalChatMessageResponse
    let done_reason: String
    let done: Bool
    let total_duration: Int
    let load_duration: Int
    let prompt_eval_count: Int
    let prompt_eval_duration: Int
    let eval_count: Int
    let eval_duration: Int
}

struct LocalChatMessageResponse: Codable {
    let role: String
    let content: String
}

