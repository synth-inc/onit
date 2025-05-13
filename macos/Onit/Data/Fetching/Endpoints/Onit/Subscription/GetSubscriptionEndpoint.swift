//
//  GetSubscriptionEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 4/29/25.
//

import Foundation

extension FetchingClient {
    func getSubscription() async throws -> Subscription? {
        let endpoint = GetSubscriptionEndpoint()
        return try await execute(endpoint)
    }
}

struct GetSubscriptionEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = Subscription?

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/subscription" }

    var getParams: [String : String]? { nil }

    var method: HTTPMethod { .get }

    var token: String? { TokenManager.token }

    var requestBody: Request? { nil }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }
}
