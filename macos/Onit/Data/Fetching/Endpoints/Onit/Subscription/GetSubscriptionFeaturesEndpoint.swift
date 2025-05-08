//
//  GetSubscriptionFeaturesEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 5/6/25.
//

import Foundation

extension FetchingClient {
    func getSubscriptionFeatures() async throws -> [SubscriptionFeature] {
        let endpoint = GetSubscriptionFeaturesEndpoint()
        return try await execute(endpoint)
    }
}

struct GetSubscriptionFeaturesEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = [SubscriptionFeature]

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/subscription/features" }

    var getParams: [String : String]? { nil }

    var method: HTTPMethod { .get }

    var token: String? { TokenManager.token }

    var requestBody: Request? { nil }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }

}
