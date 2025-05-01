//
//  DeleteAccountEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 5/1/25.
//

import Foundation

extension FetchingClient {
    func deleteAccount() async throws -> Void {
        let endpoint = DeleteAccountEndpoint()
        let _ = try await execute(endpoint)
    }
}

struct DeleteAccountEndpoint: Endpoint {
    typealias Request = EmptyRequest
    
    typealias Response = EmptyResponse?
    
    var baseURL: URL { OnitServer.baseURL }
    
    var path: String { "/v1/auth/account" }
    
    var getParams: [String : String]? { nil }
    
    var method: HTTPMethod { .delete }
    
    var token: String? { TokenManager.token }
    
    var requestBody: Request? { nil }
    
    var additionalHeaders: [String : String]? { nil }
    
    var timeout: TimeInterval? { nil }
    
}

