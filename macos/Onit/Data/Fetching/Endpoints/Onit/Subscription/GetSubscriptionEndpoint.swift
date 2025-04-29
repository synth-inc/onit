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
        let response = try await execute(endpoint)
        return response
    }
}

struct GetSubscriptionEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = Subscription?

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/subscription" }

    var getParams: [String : String]?

    var method: HTTPMethod { .get }

    var token: String? { TokenManager.token }

    var requestBody: Request?

    var additionalHeaders: [String : String]?

    var timeout: TimeInterval?

}
