//
//  UpdatePasswordEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/23/25.
//

import Foundation

extension FetchingClient {
    func updatePassword(password: String) async throws -> Void {
        let endpoint = UpdatePasswordEndpoint(password: password)
        let _ = try await execute(endpoint)
    }
}

struct UpdatePasswordEndpoint: Endpoint {
    typealias Request = UpdatePasswordRequest
    
    typealias Response = EmptyResponse?
    
    var baseURL: URL { OnitServer.baseURL }
    
    var path: String { "/v1/auth/password" }
    
    var getParams: [String : String]? { nil }
    
    var method: HTTPMethod { .patch }
    
    var token: String? { TokenManager.token }
    
    let password: String
    
    var requestBody: Request? {
        UpdatePasswordRequest(password: password)
    }
    
    var additionalHeaders: [String : String]? { nil }
    
    var timeout: TimeInterval? { nil }
    
}

struct UpdatePasswordRequest: Codable {
    let password: String
}
