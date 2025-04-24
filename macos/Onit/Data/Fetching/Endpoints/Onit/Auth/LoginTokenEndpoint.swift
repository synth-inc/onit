//
//  LoginTokenEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/21/25.
//

import Foundation

extension FetchingClient {
    func loginToken(loginToken: String) async throws -> LoginResponse {
        let endpoint = LoginTokenEndpoint(loginToken: loginToken)
        let response = try await execute(endpoint)
        return response
    }
}

struct LoginTokenEndpoint: Endpoint {
    typealias Request = LoginTokenRequest
    
    typealias Response = LoginResponse
    
    var baseURL: URL { OnitServer.baseURL }
    
    var path: String { "/v1/auth/login/token" }
    
    var getParams: [String : String]? { nil }
    
    var method: HTTPMethod { .post }
    
    var token: String? { nil }
    
    let loginToken: String
    
    var requestBody: Request? {
        LoginTokenRequest(token: loginToken)
    }
    
    var additionalHeaders: [String : String]? { nil }
    
    var timeout: TimeInterval? { nil }
    
}

struct LoginTokenRequest: Codable {
    let token: String
}
