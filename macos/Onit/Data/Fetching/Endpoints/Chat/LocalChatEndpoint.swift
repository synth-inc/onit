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
        var options: LocalChatOptions?
        var keepAlive: String?
        
        DispatchQueue.main.sync {
            keepAlive = Defaults[.localKeepAlive]
            
            // Only create options if at least one parameter is set
            if Defaults[.localNumCtx] != nil || Defaults[.localTemperature] != nil ||
                Defaults[.localTopP] != nil || Defaults[.localTopK] != nil {
                options = LocalChatOptions(
                    num_ctx: Defaults[.localNumCtx],
                    temperature: Defaults[.localTemperature],
                    top_p: Defaults[.localTopP],
                    top_k: Defaults[.localTopK]
                )
            }
        }
        
        return LocalChatRequestJSON(
            model: model,
            messages: messages,
            stream: false,
            keep_alive: keepAlive,
            options: options
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

