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
            SystemPrompt(name: "Output-only response",
                         prompt: "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go.",
                         applications: [],
                         tags: ["sales@checkbin.dev", "python"]),
            SystemPrompt(name: "Output-only response",
                         prompt: "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go.",
                         applications: [],
                         tags: ["sales@checkbin.dev", "python"]),
            SystemPrompt(name: "Output-only response",
                         prompt: "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go.",
                         applications: [],
                         tags: ["sales@checkbin.dev", "python"]),
            SystemPrompt(name: "Output-only response",
                         prompt: "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go.",
                         applications: [],
                         tags: ["sales@checkbin.dev", "python"]),
            SystemPrompt(name: "Output-only response",
                         prompt: "Based on the provided instructions, either provide the output or answer any questions related to it. Provide the response without any additional comments. Provide the output ready to go.",
                         applications: [],
                         tags: ["sales@checkbin.dev", "python"])
        ]
    }()
}
