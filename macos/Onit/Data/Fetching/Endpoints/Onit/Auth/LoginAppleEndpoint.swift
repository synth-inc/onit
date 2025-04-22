//
//  LoginAppleEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/21/25.
//

import Foundation

extension FetchingClient {
    func loginApple(idToken: String) async throws -> LoginResponse {
        let endpoint = LoginAppleEndpoint(idToken: idToken)
        let response = try await execute(endpoint)
        return response
    }
}

struct LoginAppleEndpoint: Endpoint {
    typealias Request = LoginAppleRequest
    
    typealias Response = LoginResponse
    
    var baseURL: URL { OnitServer.baseURL }
    
    var path: String { "/auth/login/apple" }
    
    var getParams: [String : String]? { nil }
    
    var method: HTTPMethod { .post }
    
    var token: String? { nil }
    
    let idToken: String
    
    var requestBody: Request? {
        LoginAppleRequest(idToken: idToken)
    }
    
    var additionalHeaders: [String : String]? { nil }
    
    var timeout: TimeInterval? { nil }
    
}

struct LoginAppleRequest: Codable {
    let idToken: String
}
