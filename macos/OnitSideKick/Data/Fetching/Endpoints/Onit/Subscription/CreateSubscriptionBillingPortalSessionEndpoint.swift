//
//  CreateSubscriptionBillingPortalSessionEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 5/6/25.
//

import Foundation

extension FetchingClient {
    func createSubscriptionBillingPortalSession() async throws -> CreateSubscriptionBillingPortalSessionResponse {
        let endpoint = CreateSubscriptionBillingPortalSessionEndpoint()
        return try await execute(endpoint)
    }
}

struct CreateSubscriptionBillingPortalSessionEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = CreateSubscriptionBillingPortalSessionResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/subscription/stripe/billing-portal" }

    var getParams: [String : String]? { nil }

    var method: HTTPMethod { .post }

    var token: String? { TokenManager.token }

    var requestBody: Request? { nil }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }

}

struct CreateSubscriptionBillingPortalSessionResponse: Codable {
    let sessionUrl: String
}
