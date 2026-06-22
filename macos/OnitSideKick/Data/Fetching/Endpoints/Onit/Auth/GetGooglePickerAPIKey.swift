//
//  GetGooglePickerAPIKey.swift
//  Onit
//
//  Created by Jay Swanson on 6/23/25.
//

import Foundation

extension FetchingClient {
    func getGooglePickerAPIKey() async throws -> String {
        let endpoint = GetGooglePickerAPIKeyEndpoint()
        let response = try await execute(endpoint)
        return response.key
    }
}

struct GetGooglePickerAPIKeyEndpoint: Endpoint {
    typealias Request = EmptyRequest

    typealias Response = GooglePickerAPIKeyResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/auth/google-picker-api-key" }

    var getParams: [String: String]? { nil }

    var method: HTTPMethod { .get }

    var token: String? { TokenManager.token }

    var requestBody: Request? { nil }

    var additionalHeaders: [String: String]? { nil }

    var timeout: TimeInterval? { nil }

}

struct GooglePickerAPIKeyResponse: Codable {
    let key: String
}
