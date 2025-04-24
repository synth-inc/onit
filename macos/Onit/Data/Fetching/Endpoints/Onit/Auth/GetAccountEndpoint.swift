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
        let response = try await execute(endpoint)
        return response
    }
}

struct GetAccountEndpoint: Endpoint {
    typealias Request = EmptyRequest
    
    typealias Response = Account
    
    var baseURL: URL { OnitServer.baseURL }
    
    var path: String { "/auth/account" }
    
    var getParams: [String : String]? { nil }
    
    var method: HTTPMethod { .get }
    
    var token: String? { TokenManager.token }
    
    var requestBody: Request? { nil }
    
    var additionalHeaders: [String : String]?
    
    var timeout: TimeInterval? { nil }
    
}
