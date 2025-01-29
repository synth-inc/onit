import Defaults
import Foundation
import SwiftData

@Model
class CustomProvider: Codable, Defaults.Serializable {
    var name: String
    var baseURL: String
    var token: String
    var models: [String]
    var isEnabled: Bool {
        didSet {
            // Update model visibility when enabled state changes
            let modelIds = Set(models)
            if isEnabled {
                // Add model IDs to visible set
                Defaults[.visibleModelIds].formUnion(modelIds)
            } else {
                // Remove model IDs from visible set
                Defaults[.visibleModelIds].subtract(modelIds)
            }
        }
    }
    
    init(name: String, baseURL: String, token: String) {
        self.name = name
        self.baseURL = baseURL
        self.token = token
        self.models = []
        self.isEnabled = true
    }
    
    func fetchModels() async throws {
        guard let url = URL(string: baseURL) else { return }
        
        let endpoint = CustomModelsEndpoint(baseURL: url, token: token)
        let client = FetchingClient()
        let response = try await client.execute(endpoint)
        
        models = response.data.map { $0.id }
        
        // Initialize model IDs
        let newModels = models.map { modelId in
            AIModel(from: CustomModelInfo(
                id: modelId,
                object: "model",
                created: Int(Date().timeIntervalSince1970),
                owned_by: name
            ), provider: self)
        }
        
        // Add new models to available remote models
        Defaults[.availableRemoteModels].append(contentsOf: newModels)
        
        // Initialize visible model IDs
        for model in newModels {
            Defaults[.visibleModelIds].insert(model.id)
        }
    }
    
    // MARK: - Decodable
    
    enum CodingKeys: CodingKey {
        case name
        case baseURL
        case token
        case models
        case isEnabled
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        baseURL = try container.decode(String.self, forKey: .baseURL)
        token = try container.decode(String.self, forKey: .token)
        models = try container.decode([String].self, forKey: .models)
        isEnabled = try container.decode(Bool.self, forKey: .isEnabled)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(baseURL, forKey: .baseURL)
        try container.encode(token, forKey: .token)
        try container.encode(models, forKey: .models)
        try container.encode(isEnabled, forKey: .isEnabled)
    }
}
