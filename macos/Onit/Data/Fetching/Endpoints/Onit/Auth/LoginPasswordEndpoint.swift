//
//  LoginPasswordEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/24/25.
//

import Foundation

extension FetchingClient {
    func loginPassword(email:String, password: String) async throws -> LoginResponse {
        let endpoint = LoginPasswordEndpoint(email: email, password: password)
        let response = try await execute(endpoint)
        return response
    }
}

struct LoginPasswordEndpoint: Endpoint {
    typealias Request = LoginPasswordRequest
    
    typealias Response = LoginResponse
    
    var baseURL: URL { OnitServer.baseURL }
    
    var path: String { "/v1/auth/login/password" }
    
    var getParams: [String : String]? { nil }
    
    var method: HTTPMethod { .post }
    
    var token: String? { nil }
    
    let email: String
    
    let password: String
    
    var requestBody: Request? {
        LoginPasswordRequest(email: email, password: password)
    }
    
    var additionalHeaders: [String : String]? { nil }
    
    var timeout: TimeInterval? { nil }
    
}

struct LoginPasswordRequest: Codable {
    let email: String
    let password: String
}
