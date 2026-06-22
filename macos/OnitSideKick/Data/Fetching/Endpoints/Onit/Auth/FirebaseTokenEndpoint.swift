//
//  FirebaseTokenEndpoint.swift
//  Onit
//
//  Created by Kévin Naudin on 2026-04-30.
//

import Foundation

extension FetchingClient {
    func fetchFirebaseToken() async throws -> FirebaseTokenResponse {
        let endpoint = FirebaseTokenEndpoint()
        return try await execute(endpoint)
    }
}

struct FirebaseTokenResponse: Decodable {
    let token: String
}

struct FirebaseTokenEndpoint: Endpoint {
    typealias Request = EmptyRequest
    typealias Response = FirebaseTokenResponse

    var baseURL: URL { OnitServer.baseURL }
    var path: String { "/v1/auth/firebase-token" }
    var getParams: [String: String]? { nil }
    var method: HTTPMethod { .post }
    var token: String? { TokenManager.token }
    var requestBody: Request? { nil }
    var additionalHeaders: [String: String]? { nil }
    var timeout: TimeInterval? { nil }
}
