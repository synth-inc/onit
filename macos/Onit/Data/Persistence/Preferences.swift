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
    var visibleModels: Set<AIModel> = Set([
        // Default OpenAI models
        .o1,
        .o1Mini,
        .gpt4o,
        // Default Anthropic models
        .claude35SonnetLatest,
        .claude35HaikuLatest,
        // Default xAI models
        .grok2,
        .grok2Vision,
    ])
    
    var visibleModelsList: [AIModel] {
        AIModel.allCases.filter { visibleModels.contains($0) }
    }
}
