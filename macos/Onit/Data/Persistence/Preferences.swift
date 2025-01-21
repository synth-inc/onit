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
        if let data = UserDefaults.standard.data(forKey: key),
           let preferences = try? JSONDecoder().decode(Preferences.self, from: data) {
            return preferences
        }
        return Preferences()
    }
    
    var model: AIModel?
    var localModel: String? = nil
    var mode: InferenceMode = .remote
    var availableLocalModels: [String] = []
    var visibleModelIds: Set<String> = Set([
        // Default OpenAI models
        "o1",
        "o1-mini",
        "gpt-4o",
        // Default Anthropic models
        "claude-3-5-sonnet-latest",
        "claude-3-5-haiku-latest",
        // Default xAI models
        "grok-2-1212",
        "grok-2-vision-1212",
    ])
    
    private var cachedModels: [AIModel]?
    
    mutating func updateCachedModels(_ models: [AIModel]) {
        cachedModels = models
    }
    
    var visibleModelsList: [AIModel] {
        guard let models = cachedModels else { return [] }
        return models.filter { visibleModelIds.contains($0.id) }
    }
}
