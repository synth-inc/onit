import Defaults
import Foundation
import SwiftData

class CustomProvider: Codable, Identifiable, Defaults.Serializable {
    var id: String { name }

    var name: String
    var baseURL: String
    var token: String
    var models: [AIModel]
    var isEnabled: Bool
    var isTokenValidated: Bool

    init(name: String, baseURL: String, token: String, models: [AIModel]) {
        self.name = name
        self.baseURL = baseURL
        self.token = token
        self.models = models
        self.isEnabled = true
        self.isTokenValidated = false
    }

    static func == (lhs: CustomProvider, rhs: CustomProvider) -> Bool {
        return lhs.name == rhs.name && lhs.baseURL == rhs.baseURL
            && lhs.token == rhs.token && lhs.models == rhs.models
            && lhs.isEnabled == rhs.isEnabled
            && lhs.isTokenValidated == rhs.isTokenValidated
    }

    @MainActor
    func fetchModels() async throws {
        guard let url = URL(string: baseURL) else { throw URLError(.badURL) }

        let endpoint = CustomModelsEndpoint(baseURL: url, token: token)
        let client = FetchingClient()
        let response = try await client.execute(endpoint)

        // Initialize model IDs
        models = response.data.map { model in
            AIModel(from: model, providerName: name)
        }
    }
}
