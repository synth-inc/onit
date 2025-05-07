//
//  GetSubscriptionFreeTrialAvailableEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 5/6/25.
//

import Foundation

extension FetchingClient {
    func getSubscriptionFreeTrialAvailable() async throws -> Bool {
        let endpoint = GetSubscriptionFreeTrialAvailableEndpoint()
        let reponse = try await execute(endpoint)
        return reponse.freeTrialAvailable
    }
}

struct GetSubscriptionFreeTrialAvailableEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = GetSubscriptionFreeTrialAvailableResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/subscription/free-trial-available" }

    var getParams: [String : String]? { nil }

    var method: HTTPMethod { .get }

    var token: String? { TokenManager.token }

    var requestBody: Request? { nil }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }

}

struct GetSubscriptionFreeTrialAvailableResponse: Codable {
    let freeTrialAvailable: Bool
}
