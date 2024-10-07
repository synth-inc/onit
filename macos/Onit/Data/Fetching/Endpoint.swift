//
//  Endpoint.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

protocol Endpoint {
    associatedtype Request: Encodable
    associatedtype Response: Decodable

    var path: String { get }
    var method: HTTPMethod { get }
    var token: String? { get }
    var requestBody: Request? { get }
    var additionalHeaders: [String: String]? { get }
}
