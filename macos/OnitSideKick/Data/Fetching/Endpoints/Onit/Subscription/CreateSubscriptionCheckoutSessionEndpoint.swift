//
//  CreateSubscriptionCheckoutSessionEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 5/6/25.
//

import Foundation

extension FetchingClient {
    func createSubscriptionCheckoutSession() async throws -> CreateSubscriptionCheckoutSessionResponse {
        let endpoint = CreateSubscriptionCheckoutSessionEndpoint()
        return try await execute(endpoint)
    }
}

struct CreateSubscriptionCheckoutSessionEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = CreateSubscriptionCheckoutSessionResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/subscription/stripe/checkout" }

    var getParams: [String : String]? { nil }

    var method: HTTPMethod { .post }

    var token: String? { TokenManager.token }

    var requestBody: Request? { nil }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }

}

struct CreateSubscriptionCheckoutSessionResponse: Codable {
    let sessionUrl: String
}
