//
//  Endpoint.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation
import EventSource

protocol Endpoint: Sendable {
    associatedtype Request: Encodable
    associatedtype Response: Decodable

    var baseURL: URL { get }
    var path: String { get }
    var getParams: [String: String]? { get }
    var method: HTTPMethod { get }
    var token: String? { get }
    var requestBody: Request? { get }
    var additionalHeaders: [String: String]? { get }
    var timeout: TimeInterval? { get }
    
    func getContent(response: Response) -> String?
    func getToolResponse(response: Response) -> ChatResponse?
}

extension Endpoint {
    func getContent(response: Response) -> String? {
        return nil
    }
    
    func getToolResponse(response: Response) -> ChatResponse? {
        return nil
    }
}
