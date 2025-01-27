//
//  Preferences.swift
//  Onit
//
//  Created by Benjamin Sage on 10/11/24.
//

import Foundation

struct Preferences: Codable {
    static let shared = Preferences.load()
    
    private static let key = "app_preferences"
    
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
    var remoteFetchFailed: Bool = false
    var visibleModelIds: Set<String> = Set([])
    var localEndpointURL: String = "http://localhost:11434"
    
    mutating func markRemoteModelAsNotNew(modelId: String) {
        if let index = availableRemoteModels.firstIndex(where: { $0.id == modelId }) {
            availableRemoteModels[index].isNew = false
        }
    }

    mutating func initializeVisibleModelIds(from models: [AIModel]) {
        if visibleModelIds.isEmpty {
            visibleModelIds = Set(models.filter { $0.defaultOn }.map { $0.id })
        }
    }

    var visibleModelsList: [AIModel] {
        return availableRemoteModels.filter { visibleModelIds.contains($0.id) }
    }
}
