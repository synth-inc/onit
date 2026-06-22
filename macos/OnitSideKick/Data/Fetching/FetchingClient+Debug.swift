//
//  FetchingClient+Debug.swift
//  Onit
//
//  Created by timl on 3/4/25.
//

import Foundation

extension FetchingClient {
    public static func printCurlRequest<E: Endpoint>(endpoint: E, url: URL) {
        // Helpful debugging method
        let encoder = JSONEncoder()
        print("CURL Request:")
        print("curl -X \(endpoint.method.rawValue) \(url.absoluteString) \\")
        print("  -H 'Content-Type: application/json' \\")
        if let token = endpoint.token {
            print("  -H 'Authorization: Bearer \(token)' \\")
        }
        if let additionalHeaders = endpoint.additionalHeaders {
            for (header, value) in additionalHeaders {
                print("  -H '\(header): \(value)' \\")
            }
        }
        if let requestBody = endpoint.requestBody {
            if let jsonData = try? encoder.encode(requestBody),
                let jsonString = String(data: jsonData, encoding: .utf8)
            {
                print("  -d '\(jsonString)'")
            }
        }
    }
}
