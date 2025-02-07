//
//  SystemPrompt.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import Foundation
import SwiftData

@Model
class SystemPrompt {
    @Attribute(.unique)
    var id: UUID
    
    var name: String
    var prompt: String
    var applications: [URL]
    var tags: [String]
    
    init() {
        id = UUID()
        name = ""
        prompt = "Enter instructions to define role, tone and boundaries of the AI"
        applications = []
        tags = []
    }
    
    init(id: UUID = UUID(), name: String, prompt: String, applications: [URL], tags: [String]) {
        self.id = id
        self.name = name
        self.prompt = prompt
        self.applications = applications
        self.tags = tags
    }
}
