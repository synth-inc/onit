//
//  StreamingEndpoint.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation
import EventSource

protocol StreamingEndpoint: Endpoint {    
    func getContentFromSSE(event: EVEvent) throws -> StreamingEndpointResponse?
    func getStreamingErrorMessage(data: Data) -> String?
}

extension StreamingEndpoint {
    func getContentFromSSE(event: EVEvent) throws -> StreamingEndpointResponse? {
        return nil
    }
    func getStreamingErrorMessage(data: Data) -> String? {
        return nil
    }
    
    func asURLRequest() throws -> URLRequest {
        var url = baseURL.appendingPathComponent(path)
        
        if let getParams = getParams {
            if !getParams.isEmpty {
                var urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false)
                urlComponents?.queryItems = getParams.map { URLQueryItem(name: $0.key, value: $0.value) }
                if let updatedURL = urlComponents?.url {
                    url = updatedURL
                }
            }
        }
        
        var request = URLRequest(url: url)

        request.httpMethod = method.rawValue
        
        if let requestBody = requestBody {
            let data = try JSONEncoder().encode(requestBody)
            request.httpBody = data
        }
        
        request.addAuthorization(token: token)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.addContentType(for: method, defaultType: "application/json")

        additionalHeaders?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}

struct StreamingEndpointResponse {
    let content: String?
    let functionName: String?
    let functionArguments: String?
}
