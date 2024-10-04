//
//  FetchingClient+URL.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation

extension FetchingClient {
    public func url(withPath path: String, query: [String: String]? = nil) -> URL {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            return baseURL.appendingPathComponent(path)
        }

        components.path = components.path + path

        if let query = query {
            components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        return components.url ?? baseURL.appendingPathComponent(path)
    }
}

