//
//  TypeaheadTestResultEndpoint.swift
//  Onit
//
//  Created by Kévin Naudin on 06/03/2025.
//

import Foundation

extension FetchingClient {
    func sendTestResults(_ results: [TypeaheadTestResult]) async throws {
        let endpoint = TypeaheadTestResultEndpoint(results: results)
        let _ = try await execute(endpoint)
    }
}

struct TypeaheadTestResultEndpoint: Endpoint {
    var baseURL: URL = URL(string: "https://onit-server-v2-a93590258ea2.herokuapp.com")!

    typealias Request = TypeaheadTestResultRequest
    typealias Response = TypeaheadTestResultResponse
    
    let results: [TypeaheadTestResult]
    
    var token: String? { nil }
    var path: String { "/test/results" }
    var getParams: [String : String]? { nil }
    var method: HTTPMethod { .post }
    
    var requestBody: TypeaheadTestResultRequest? {
        TypeaheadTestResultRequest(results: results)
    }
    
    var additionalHeaders: [String : String]? { nil }
    var timeout: TimeInterval? { nil }
}

struct TypeaheadTestResultRequest: Codable {
    let results: [TypeaheadTestResult]
}

struct TypeaheadTestResultResponse: Codable {
    let message: String
    let count: Int
}
