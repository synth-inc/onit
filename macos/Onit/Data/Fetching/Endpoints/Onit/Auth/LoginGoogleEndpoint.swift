//
//  LoginGoogleEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/21/25.
//

import Foundation

extension FetchingClient {
    func loginGoogle(idToken: String) async throws -> LoginResponse {
        let endpoint = LoginGoogleEndpoint(idToken: idToken)
        let response = try await execute(endpoint)
        return response
    }
}

struct LoginGoogleEndpoint: Endpoint {
    typealias Request = LoginGoogleRequest
    
    typealias Response = LoginResponse
    
    var baseURL: URL { OnitServer.baseURL }
    
    var path: String { "/login/google" }
    
    var getParams: [String : String]? { nil }
    
    var method: HTTPMethod { .post }
    
    var token: String? { nil }
    
    let idToken: String
    
    var requestBody: Request? {
        LoginGoogleRequest(idToken: idToken)
    }
    
    var additionalHeaders: [String : String]? { nil }
    
    var timeout: TimeInterval? { nil }
    
}

struct LoginGoogleRequest: Codable {
    let idToken: String
}
