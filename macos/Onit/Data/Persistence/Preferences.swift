//
//  Preferences.swift
//  Onit
//
//  Created by Benjamin Sage on 10/11/24.
//

import Foundation

class Preferences: Codable {
    @MainActor static let shared = Preferences.load()
    
    private static let key = "app_preferences"
    
    let id: UUID = UUID()
    
    static func save(_ preferences: Preferences) {
        if let data = try? JSONEncoder().encode(preferences) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
    
    static func load() -> Preferences {
        // Never commit this uncommented!!
        // UserDefaults.standard.removeObject(forKey: key)

        if let data = UserDefaults.standard.data(forKey: key),
           let preferences = try? JSONDecoder().decode(Preferences.self, from: data) {
            return preferences
        }


        return Preferences()
    }
    
    var remoteModel: AIModel?
    var localModel: String? = nil
    var mode: InferenceMode = .remote
    var availableLocalModels: [String] = []
    var availableRemoteModels: [AIModel] = []
    var visibleModelIds: Set<String> = Set([])
    var localEndpointURL: URL = URL(string: "http://localhost:11434")!
    
    // Local model advanced options
    var localKeepAlive: String?
    var localNumCtx: Int?
    var localTemperature: Double?
    var localTopP: Double?
    var localMinP: Double?

    func markRemoteModelAsNotNew(modelId: String) {
        if let index = availableRemoteModels.firstIndex(where: { $0.id == modelId }) {
            availableRemoteModels[index].isNew = false
        }
    }

    func initializeVisibleModelIds(from models: [AIModel]) {
        if visibleModelIds.isEmpty {
            visibleModelIds = Set(models.filter { $0.defaultOn }.map { $0.id })
        }
    }

    var visibleModelsList: [AIModel] {
        return availableRemoteModels.filter { visibleModelIds.contains($0.id) }
    }
}
