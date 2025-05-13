//
//  GetAccountEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/23/25.
//

import Foundation

extension FetchingClient {
    func getAccount() async throws -> Account {
        let endpoint = GetAccountEndpoint()
        return try await execute(endpoint)
    }
}

struct GetAccountEndpoint: Endpoint {
    typealias Request = EmptyRequest
    
    typealias Response = Account
    
    var baseURL: URL { OnitServer.baseURL }
    
    var path: String { "/v1/auth/account" }
    
    var getParams: [String : String]? { nil }
    
    var method: HTTPMethod { .get }
    
    var token: String? { TokenManager.token }
    
    var requestBody: Request? { nil }
    
    var additionalHeaders: [String : String]? { nil }
    
    var timeout: TimeInterval? { nil }
    
}
