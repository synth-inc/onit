//
//  LocalGenerateStreamingEndpoint.swift
//  Onit
//
//  Created by Kévin Naudin on 06/02/2025.
//

import Defaults
import EventSource
import Foundation

struct LocalGenerateStreamingEndpoint: StreamingEndpoint {
    var additionalHeaders: [String : String]?
    
    typealias Request = LocalGenerateRequestJSON
    typealias Response = LocalGenerateStreamingResponse

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
            stream: true,
            keep_alive: keepAlive,
            options: newOptions
        )
    }

    func getContentFromSSE(event: EVEvent) throws -> String? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            return response.response
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(LocalGenerateStreamingError.self, from: data)
        
        return response?.error
    }
}

struct LocalGenerateStreamingResponse: Codable {
    let model: String
    let created_at: String
    let response: String
    let done: Bool
}

struct LocalGenerateStreamingError: Codable {
    let error: String
}
