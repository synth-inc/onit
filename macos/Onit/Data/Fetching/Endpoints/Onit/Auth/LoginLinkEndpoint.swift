//
//  LoginLinkEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/21/25.
//

import Foundation

extension FetchingClient {
    func requestLoginLink(email: String) async throws -> Void {
        let endpoint = LoginLinkEndpoint(email: email)
        let _ = try await execute(endpoint)
    }
}

struct LoginLinkEndpoint: Endpoint {
    typealias Request = LoginLinkRequest
    
    typealias Response = EmptyResponse?
    
    var baseURL: URL { OnitServer.baseURL }
    
    var path: String { "/v1/auth/login/link" }
    
    var getParams: [String : String]? { nil }
    
    var method: HTTPMethod { .post }
    
    var token: String? { nil }
    
    let email: String

    var requestBody: Request? {
        LoginLinkRequest(email: email)
    }
    
    var additionalHeaders: [String : String]? { nil }
    
    var timeout: TimeInterval? { nil }
    
}

struct LoginLinkRequest: Codable {
    let email: String
}
