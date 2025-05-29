//
//  TypeaheadLearningService.swift
//  Onit
//
//  Created by Kévin Naudin on 03/03/2025.
//

import Combine
import Defaults
import Foundation
import SwiftData

///
/// Service which store in database each inputs from changes on :
/// - `AccessibilityNotificationsManager.shared.userInput`
/// - `AccessibilityNotificationsManager.shared.screenResult`
///
@MainActor
@Observable
class TypeaheadLearningService {
    
    // MARK: - Singleton instance
    
    static let shared = TypeaheadLearningService()
    
    // MARK: - Properties
    
    private let modelContext = ModelContext(SwiftDataContainer.appContainer)
    
    // MARK: - Private initializer
    
    private init() {
        startCollecting()
    }
    
    // MARK: - Functions
    
    private func startCollecting() {
        Task { @MainActor in
            let publisher = AccessibilityNotificationsManager.shared.$userInput
                .combineLatest(AccessibilityNotificationsManager.shared.$screenResult)
                .receive(on: RunLoop.main)
            
            var lastSavedWord = ""

            
            for try await (userInput, screenResult) in publisher.values {
                // Skip if text is empty
                guard !userInput.fullText.isEmpty else { continue }
                
                let currentText = userInput.fullText
                let cursorPosition = userInput.cursorPosition
                
                let cursorIndex = currentText.index(currentText.startIndex, offsetBy: cursorPosition)
                var traversePosition = cursorIndex
                
                // Move backwards until we find whitespace or reach the start
                var charactersBack = 0
                var wordsBack = 0
                var wordOneStartIndex = traversePosition
                
                while traversePosition > currentText.startIndex {
                    let previousIndex = currentText.index(before: traversePosition)
                    let char = currentText[previousIndex]
                    if char.isWhitespace {
                        wordsBack += 1
                        if wordsBack == 1 {
                            // Only update previousWordStartIndex if we haven't found it yet
                            if wordOneStartIndex == cursorIndex {
                                wordOneStartIndex = previousIndex
                            }
                        }
                        if wordsBack == 2 {
                            break
                        }
                    }
                    traversePosition = previousIndex
                    charactersBack += 1
                }
                let currentWordAtCursor = String(currentText[wordOneStartIndex..<cursorIndex])
                let previousWord = String(currentText[traversePosition..<wordOneStartIndex])

                if currentWordAtCursor.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !previousWord.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    if previousWord != lastSavedWord {
                        
                        lastSavedWord = previousWord
                        
                    } else {
                        print("skipping word we just done")
                    }
                }
            }
        }
    }
    
    func saveCase(input: AccessibilityUserInput, screenResult: ScreenResult) async {
        guard Defaults[.typeaheadLearningConfig].isEnabled,
              !input.fullText.isEmpty,
              let descriptor = getFetchDescriptor(input: input, screenResult: screenResult)
        else { return }
        
        let allCases = (try? modelContext.fetch(descriptor)) ?? []
        
        if let existingCase = allCases.first(where: {
            (!$0.precedingText.isEmpty && input.precedingText.starts(with: $0.precedingText)) ||
            (!input.precedingText.isEmpty && $0.precedingText.starts(with: input.precedingText))
        }) {
            existingCase.screenContent = screenResult.others?.values.joined(separator: "\n\n") ?? ""
            existingCase.currentText = input.fullText
            existingCase.precedingText = input.precedingText
            existingCase.followingText = input.followingText
            existingCase.timestamp = Date()
        } else {
            let newCase = TypeaheadCase(
                applicationName: screenResult.applicationName ?? "",
                applicationTitle: screenResult.applicationTitle,
                screenContent: screenResult.others?.values.joined(separator: "\n\n") ?? "",
                currentText: input.fullText,
                precedingText: input.precedingText,
                followingText: input.followingText
            )
            modelContext.insert(newCase)
        }
        
        try? modelContext.save()
    }
    
    func updateCase(with aiCompletion: String, input: AccessibilityUserInput, screenResult: ScreenResult) async {
        guard Defaults[.typeaheadLearningConfig].isEnabled,
              !input.fullText.isEmpty,
              let descriptor = getFetchDescriptor(input: input, screenResult: screenResult)
        else { return }
        
        let allCases = (try? modelContext.fetch(descriptor)) ?? []
        
        if let existingCase = allCases.first(where: { $0.currentText == input.fullText }) {
            existingCase.aiCompletion = aiCompletion
            existingCase.timestamp = Date()
        } else {
            let newCase = TypeaheadCase(
                applicationName: screenResult.applicationName ?? "",
                applicationTitle: screenResult.applicationTitle,
                screenContent: screenResult.others?.values.joined(separator: "\n\n") ?? "",
                currentText: input.fullText,
                precedingText: input.precedingText,
                followingText: input.followingText
            )
            newCase.aiCompletion = aiCompletion
            
            modelContext.insert(newCase)
        }
        
        try? modelContext.save()
    }
    
    func getCases(limit: Int? = nil) async throws -> [TypeaheadCase] {
        guard Defaults[.typeaheadLearningConfig].isEnabled
        else { return [] }
        
        var descriptor = FetchDescriptor<TypeaheadCase>(
            sortBy: [SortDescriptor(\TypeaheadCase.timestamp, order: .reverse)]
        )
        
        descriptor.fetchLimit = limit
        
        return try modelContext.fetch(descriptor)
    }
    
    func findSimilarCases(
        input: AccessibilityUserInput,
        screenResult: ScreenResult
    ) async -> [TypeaheadExample] {
        guard Defaults[.typeaheadLearningConfig].isEnabled,
              let descriptor = getFetchDescriptor(input: input, screenResult: screenResult)
        else { return [] }
        
        let cases = (try? modelContext.fetch(descriptor)) ?? []
        
        return cases.compactMap { typeaheadCase in
            guard let aiCompletion = typeaheadCase.aiCompletion else { return nil }
            
            return TypeaheadExample(
                applicationName: typeaheadCase.applicationName,
                windowTitle: typeaheadCase.applicationTitle,
                screenContent: typeaheadCase.screenContent,
                currentText: typeaheadCase.currentText,
                precedingText: typeaheadCase.precedingText,
                followingText: typeaheadCase.followingText,
                aiCompletion: aiCompletion
            )
        }
    }
    
    private func getFetchDescriptor(
        input: AccessibilityUserInput,
        screenResult: ScreenResult
    ) -> FetchDescriptor<TypeaheadCase>? {
        guard let applicationName = screenResult.applicationName else { return nil }
        let applicationTitle = screenResult.applicationTitle
        
        return FetchDescriptor<TypeaheadCase>(
            predicate: #Predicate<TypeaheadCase> {
                $0.applicationName == applicationName &&
                $0.applicationTitle == applicationTitle
            },
            sortBy: [
                SortDescriptor(\TypeaheadCase.timestamp, order: .reverse)
            ]
        )
    }
}
