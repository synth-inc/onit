//
//  Preferences.swift
//  Onit
//
//  Created by Benjamin Sage on 10/11/24.
//

import Foundation

struct Preferences: Codable {
    var model: AIModel?
    var localModel: String? = nil
    var mode: InferenceMode = .remote
    var incognito: Bool = false
    var visibleModels: Set<AIModel> = Set([
        // Default OpenAI models
        .gpt4Turbo,
        .gpt4Vision,
        // Default Anthropic models
        .claude3Opus,
        .claude3Sonnet,
        // Default xAI models
        .grok2,
        .grok2Vision,
    ])
    
    var visibleModelsList: [AIModel] {
        AIModel.allCases.filter { visibleModels.contains($0) }
    }
}
