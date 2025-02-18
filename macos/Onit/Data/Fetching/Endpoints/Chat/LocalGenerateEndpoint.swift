//
//  LocalGenerateEndpoint.swift
//  Onit
//
//  Created by timl on 11/14/24.
//

import Defaults
import Foundation
import PhotosUI

struct LocalGenerateEndpoint: Endpoint {
    var additionalHeaders: [String : String]?
    
    typealias Request = LocalGenerateRequestJSON
    typealias Response = LocalGenerateResponseJSON

    let model: String?
    let prompt: String
    let system: String?
    let keepAlive: String?
    let options: LocalChatOptions
    
    var baseURL: URL {
        var url: URL!
        DispatchQueue.main.sync {
            url = Defaults[.localEndpointURL]
        }
        return url
    }

    var path: String { "/api/generate" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var token: String? { nil }
    var timeout: TimeInterval? {
        DispatchQueue.main.sync {
            return Defaults[.localRequestTimeout]
        }
    }
    var requestBody: LocalGenerateRequestJSON? {
        // Only create options if at least one parameter is set
        let newOptions: LocalChatOptions?
        if options.isEmpty {
            newOptions = nil
        } else {
            newOptions = options
        }
        
        return LocalGenerateRequestJSON(
            model: model,
            prompt: prompt,
            system: system,
            stream: false,
            keep_alive: keepAlive,
            options: newOptions
        )
    }
}

// Request
struct LocalGenerateRequestJSON: Codable {
    let model: String?
    let prompt: String
    let system: String?
    let stream: Bool
    var keep_alive: String?
    let options: LocalChatOptions?
}

// Response
struct LocalGenerateResponseJSON: Codable {
    let response: String
}
