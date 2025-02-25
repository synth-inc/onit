//
//  PreviewSampleData.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import SwiftData

actor PreviewSampleData {
    
    @MainActor
    static var remoteModels: RemoteModelsState = {
        RemoteModelsState()
    }()

    @MainActor
    static var customProvider: CustomProvider = {
        CustomProvider(
            name: "Provider name", baseURL: "http://google.com", token: "aiZafeoi", models: [])
    }()
    
    @MainActor
    static let systemPrompt: SystemPrompt = {
        SystemPrompt(name: "Output-only response",
                     prompt: "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go.",
                     applications: [],
                     tags: ["sales@checkbin.dev", "python"])
    }()
    
    @MainActor
    static let systemPrompts: [SystemPrompt] = {
        [
            SystemPrompt(name: "Output-only response",
                         prompt: "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go.",
                         applications: [],
                         tags: ["sales@checkbin.dev", "python"]),
            SystemPrompt(name: "Code Review Assistant",
                         prompt: "You are a helpful code review assistant. Analyze code for bugs, style issues, and potential improvements.",
                         applications: [],
                         tags: ["code-review", "programming"]),
            SystemPrompt(name: "SQL Query Helper",
                         prompt: "Help write and optimize SQL queries. Suggest improvements and explain query plans.",
                         applications: [],
                         tags: ["database", "sql"]),
            SystemPrompt(name: "Documentation Writer",
                         prompt: "Generate clear and concise documentation for code, APIs, and technical concepts.",
                         applications: [],
                         tags: ["documentation", "technical-writing"]),
            SystemPrompt(name: "Test Case Generator",
                         prompt: "Generate comprehensive test cases for software features, including edge cases and error conditions.",
                         applications: [],
                         tags: ["testing", "quality-assurance"]),
            SystemPrompt(name: "API Design Reviewer",
                         prompt: "Review API designs for RESTful best practices, consistency, and usability.",
                         applications: [],
                         tags: ["api-design", "rest"])
        ]
    }()
}
