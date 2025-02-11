//
//  Prompt.swift
//  Onit
//
//  Created by Benjamin Sage on 10/27/24.
//

import Foundation
import SwiftData

@Model final class Prompt: Identifiable, ObservableObject {

    var systemPrompt: SystemPrompt?
    var instruction: String
    var timestamp: Date
    var input: Input?
    var contextList: [Context] = []

    //    @Relationship(deleteRule: .cascade, inverse: \Response.prompt)
    var responses: [Response] = []
    var priorInstructions: [String] = []

    var priorPrompt: Prompt?
    var nextPrompt: Prompt?

    @Transient @Published var generationState: GenerationState? = GenerationState.done
    var generationIndex = -1

    init(
        systemPrompt: SystemPrompt, instruction: String, timestamp: Date,
        input: Input? = nil, contextList: [Context] = [], responses: [Response] = []
    ) {
        self.systemPrompt = systemPrompt
        self.instruction = instruction
        self.timestamp = timestamp
        self.input = input
        self.contextList = contextList
        self.responses = responses
        self.generationState = GenerationState.done
    }

    var generation: String? {
        guard case .done = generationState else { return nil }
        guard responses.count > 0 && responses.count > generationIndex else { return nil }
        return responses[generationIndex].text
    }

    var generationCount: Int? {
        guard case .done = generationState else { return nil }
        return responses.count
    }

    var canIncrementGeneration: Bool {
        guard case .done = generationState else { return false }
        return responses.count > generationIndex + 1
    }

    var canDecrementGeneration: Bool {
        return generationIndex > 0
    }

    var fullText: String {
        let responseTexts = responses.map { $0.text }.joined(separator: "\n")
        return "\(instruction)\n\(responseTexts)"
    }
}

extension Prompt: Equatable {
    static func == (lhs: Prompt, rhs: Prompt) -> Bool {
        lhs.timestamp == rhs.timestamp
    }
}

extension Prompt {
    @MainActor static let sample = Prompt(systemPrompt: SystemPrompt.outputOnly, instruction: "Hello, world!", timestamp: .now)
}
