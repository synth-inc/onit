//
//  Prompt.swift
//  Onit
//
//  Created by Benjamin Sage on 10/27/24.
//

import Foundation
import SwiftData

@Model final class Prompt: Identifiable, ObservableObject {

    var instruction: String
    var timestamp: Date
    var input: Input?
    var contextList: [Context] = []

    //    @Relationship(deleteRule: .cascade, inverse: \Response.prompt)
    var responses: [Response] = [] {
        didSet {
            validateGenerationIndex()
        }
    }
    var priorInstructions: [String] = []

    var priorPrompt: Prompt?
    var nextPrompt: Prompt?

    @Transient @Published var generationState: GenerationState? = GenerationState.done 
    var generationIndex = -1

    init(
        instruction: String, timestamp: Date, input: Input? = nil,
        contextList: [Context] = [], responses: [Response] = []
    ) {
        self.instruction = instruction
        self.timestamp = timestamp
        self.input = input
        self.contextList = contextList
        self.responses = responses
        self.generationState = GenerationState.done
    }

    var sortedResponses: [Response] {
        return responses.sorted { $0.timestamp < $1.timestamp }
    }

    var currentResponse: Response? {
        guard sortedResponses.count > 0,
              generationIndex >= 0,
              generationIndex < sortedResponses.count else {
            return nil
        }
        return sortedResponses[generationIndex]
    }

    /// Safe generation index that's always within bounds
    var safeGenerationIndex: Int {
        guard !sortedResponses.isEmpty else { return -1 }
        return max(0, min(generationIndex, sortedResponses.count - 1))
    }
    
    /// Ensures generationIndex is always valid when responses change
    private func validateGenerationIndex() {
        if sortedResponses.isEmpty {
            generationIndex = -1
        } else if generationIndex >= sortedResponses.count {
            generationIndex = sortedResponses.count - 1
        } else if generationIndex < 0 && !sortedResponses.isEmpty {
            generationIndex = 0
        }
    }

    var generation: String? {
        guard case .done = generationState else { return nil }
        
        guard let currentResponse = currentResponse else { return nil }
        
        if currentResponse.isDiffResponse, let previewText = currentResponse.diffPreview {
            return previewText
        }
        
        return currentResponse.text
    }

    var generationCount: Int? {
        guard case .done = generationState else { return nil }
        return sortedResponses.count
    }

    var canIncrementGeneration: Bool {
        guard case .done = generationState else { return false }
        return sortedResponses.count > generationIndex + 1
    }

    var canDecrementGeneration: Bool {
        return generationIndex > 0
    }

    var fullText: String {
        let responseTexts = sortedResponses.map { $0.text }.joined(separator: "\n")
        return "\(instruction)\n\(responseTexts)"
    }

    func updateGenerationIndex(_ newIndex: Int) {
        generationIndex = newIndex
        if generationIndex >= 0 && generationIndex < sortedResponses.count {
            instruction = sortedResponses[generationIndex].instruction ?? ""
        }
    }
    
    /// Safely removes a response while maintaining valid generationIndex
    func removeResponse(at index: Int) {
        guard index >= 0 && index < responses.count else { return }
        responses.remove(at: index)
        // validateGenerationIndex() is called automatically via didSet
    }
    
    /// Safely removes the last response while maintaining valid generationIndex  
    func removeLastResponse() {
        guard !responses.isEmpty else { return }
        responses.removeLast()
        // validateGenerationIndex() is called automatically via didSet
    }
}

extension Prompt: Equatable {
    static func == (lhs: Prompt, rhs: Prompt) -> Bool {
        lhs.timestamp == rhs.timestamp
    }
}

extension Prompt {
    @MainActor static let sample = Prompt(instruction: "Hello, world!", timestamp: .now)
}
