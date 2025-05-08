//
//  UpdateSubscriptionCancelEndpoint.swift
//  Onit
//
//  Created by Jason Swanson on 5/6/25.
//

import Foundation

extension FetchingClient {
    func updateSubscriptionCancel(cancelAtPeriodEnd: Bool) async throws -> Void {
        let endpoint = UpdateSubscriptionCancelEndpoint(cancelAtPeriodEnd: cancelAtPeriodEnd)
        let _ = try await execute(endpoint)
    }
}

struct UpdateSubscriptionCancelEndpoint: Endpoint {
    typealias Request = UpdateSubscriptionCancelRequest

    typealias Response = EmptyResponse?

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/subscription/cancel" }

    var getParams: [String : String]? { nil }

    var method: HTTPMethod { .patch }

    var token: String? { TokenManager.token }

    let cancelAtPeriodEnd: Bool

    var requestBody: Request? {
        UpdateSubscriptionCancelRequest(cancelAtPeriodEnd: cancelAtPeriodEnd)
    }

    var additionalHeaders: [String : String]? { nil }

    var timeout: TimeInterval? { nil }

}

struct UpdateSubscriptionCancelRequest: Codable {
    let cancelAtPeriodEnd: Bool
}
