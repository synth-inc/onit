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
    static let shared = TypeaheadLearningService()
    private var modelContext: ModelContext?
    
    func initialize(with container: ModelContainer) {
        self.modelContext = ModelContext(container)
        startCollecting()
    }
    
    private func startCollecting() {
        Task { @MainActor in
            let publisher = Publishers.CombineLatest(
                AccessibilityNotificationsManager.shared.$userInput,
                AccessibilityNotificationsManager.shared.$screenResult
            )
            .receive(on: RunLoop.main)
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            
            for try await (userInput, screenResult) in publisher.values {
                await saveCase(input: userInput, screenResult: screenResult)
            }
        }
    }
    
    func saveCase(input: AccessibilityUserInput, screenResult: ScreenResult) async {
        guard Defaults[.typeaheadLearningConfig].isEnabled,
              let modelContext = modelContext,
              !input.fullText.isEmpty,
              let descriptor = getFetchDescriptor(input: input, screenResult: screenResult)
        else { return }
        
        let allCases = (try? modelContext.fetch(descriptor)) ?? []
        
        if let existingCase = allCases.first(where: { $0.currentText == input.fullText }) {
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
    
    func updateCase(input: AccessibilityUserInput, screenResult: ScreenResult, aiCompletion: String) async {
        guard Defaults[.typeaheadLearningConfig].isEnabled,
              let modelContext = modelContext,
              !input.fullText.isEmpty,
              let descriptor = getFetchDescriptor(input: input, screenResult: screenResult)
        else { return }
        
        let allCases = (try? modelContext.fetch(descriptor)) ?? []
        
        if let existingCase = allCases.first(where: { $0.currentText == input.fullText }) {
            existingCase.aiCompletion = aiCompletion
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
    
    func findSimilarCases(
        input: AccessibilityUserInput,
        screenResult: ScreenResult
    ) async -> [TypeaheadExample] {
        guard Defaults[.typeaheadLearningConfig].isEnabled,
              let modelContext = modelContext,
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
