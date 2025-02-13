//
//  LocalChatStreamingEndpoint.swift
//  Onit
//
//  Created by Kévin Naudin on 06/02/2025.
//

import Defaults
import EventSource
import Foundation

struct LocalChatStreamingEndpoint: StreamingEndpoint {
    var additionalHeaders: [String : String]?
    
    typealias Request = LocalChatRequestJSON
    typealias Response = LocalChatStreamingResponse

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
            stream: true,
            keep_alive: keepAlive,
            options: newOptions
        )
    }

    func getContentFromSSE(event: EVEvent) throws -> String? {
        if let data = event.data?.data(using: .utf8) {
            let response = try JSONDecoder().decode(Response.self, from: data)
            
            return response.message?.content
        }
        
        return nil
    }
    
    func getStreamingErrorMessage(data: Data) -> String? {
        let response = try? JSONDecoder().decode(LocalChatStreamingError.self, from: data)
        
        return response?.error
    }
}

struct LocalChatStreamingResponse: Codable {
    let message: Message?
    let done: Bool
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct LocalChatStreamingError: Codable {
    let error: String
}
