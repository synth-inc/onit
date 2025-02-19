//
//  SystemPrompt.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import Defaults
import Foundation
import SwiftData

@Model
class SystemPrompt {
    
    @Attribute(.unique)
    var id: String
    
    var name: String
    var prompt: String
    var applications: [URL]
    var tags: [String]
    var timestamp: Date
    var lastUsed: Date?
    
    init() {
        id = UUID().uuidString
        name = ""
        prompt = "Enter instructions to define role, tone and boundaries of the AI"
        applications = []
        tags = []
        timestamp = Date()
    }
    
    init(id: String = UUID().uuidString, name: String, prompt: String, applications: [URL], tags: [String], timestamp: Date = Date()) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.applications = applications
        self.tags = tags
        self.timestamp = timestamp
    }
    
    static var outputOnly: SystemPrompt {
        SystemPrompt(
            id: "output-only",
            name: "Output-only response",
            prompt: "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go.",
            applications: [],
            tags: []
        )
    }
}

// MARK: - Equatable

extension SystemPrompt: Equatable {
    static func == (lhs: SystemPrompt, rhs: SystemPrompt) -> Bool {
        return lhs.id == rhs.id && lhs.name == rhs.name &&
            lhs.prompt == rhs.prompt && lhs.applications == rhs.applications &&
            lhs.tags == rhs.tags && lhs.timestamp == rhs.timestamp &&
            lhs.lastUsed == rhs.lastUsed
    }
}
