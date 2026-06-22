//
//  ResolveAppCategoryEndpoint.swift
//  Onit
//
//  Created by Kévin Naudin on 2026-02-13.
//

import Foundation

extension FetchingClient {
    func resolveAppCategory(appBundleId: String?, appName: String?) async throws -> AppCategoryResponse {
        let endpoint = ResolveAppCategoryEndpoint(appBundleId: appBundleId, appName: appName)
        return try await execute(endpoint)
    }
}

struct ResolveAppCategoryEndpoint: Endpoint {
    typealias Request = ResolveAppCategoryRequest

    typealias Response = AppCategoryResponse

    var baseURL: URL { OnitServer.baseURL }

    var path: String { "/v1/transcription/resolve-app-category" }

    var getParams: [String: String]? { nil }

    var method: HTTPMethod { .post }

    var token: String? { TokenManager.token }

    let appBundleId: String?
    let appName: String?

    var requestBody: Request? {
        ResolveAppCategoryRequest(appBundleId: appBundleId, appName: appName)
    }

    var additionalHeaders: [String: String]? { nil }

    var timeout: TimeInterval? { 10 }
}

struct ResolveAppCategoryRequest: Codable {
    let appBundleId: String?
    let appName: String?
}

struct AppCategoryResponse: Codable {
    let appCategory: String
    let categoryDescription: String
    let source: String
}
