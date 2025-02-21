//
//  TypeAheadState.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import Defaults
import SwiftUI

@Observable
@MainActor
final class TypeAheadState {
    
    // MARK: - Singleton instance
    
    @MainActor
    static let shared = TypeAheadState()
    
    // MARK: - Properties
    
    var completion: String = ""
    var isLoading = false
    var error: TypeAheadError?
    var isCompletionInserted = false
    
    var showMenu = false
    
    private(set) var shouldShow: Bool = false
    
    private let moreSuggestionsState = TypeAheadMoreSuggestionsState.shared
    private var currentTaskId: UUID?
    private var shouldSkipNextUpdate: Bool = false
    
    // MARK: - Initializer
    
    private init() {
        // Listen for userInput changes
        Task { @MainActor in
            let manager = AccessibilityNotificationsManager.shared
            
            for try await userInput in manager.$userInput.values {
                Task { @MainActor in
                    let taskId = UUID()

                    currentTaskId = taskId
                    updateShouldShow(userInput: userInput)
                    
                    guard shouldShow else {
                        reset()
                        
                        return
                    }
                    
                    if shouldSkipNextUpdate {
                        shouldSkipNextUpdate = false
                        return
                    }
                    
                    await requestCompletion(taskId: taskId)
                }
            }
        }
    }
    
    // MARK: - Functions
    
    func insertSuggestion() {
        if let hoveredIndex = moreSuggestionsState.hoveredIndex,
           hoveredIndex < moreSuggestionsState.moreSuggestions.count {
            insertSuggestion(text: moreSuggestionsState.moreSuggestions[hoveredIndex])
        } else {
            insertSuggestion(text: completion)
        }
    }
    
    // MARK: - Private functions
    
    private func reset(loading: Bool = false, inserted: Bool = false) {
        completion = ""
        isLoading = loading
        error = nil
        isCompletionInserted = inserted
        
        moreSuggestionsState.reset()
    }
    
    private func insertSuggestion(text: String) {
        if !isLoading && !text.isEmpty {
            // Copy/Paste trick
            let pasteboard = NSPasteboard.general
            let oldValue = pasteboard.string(forType: .string) ?? ""
            
            pasteboard.clearContents()
            pasteboard.setString(text, forType: .string)

            let source = CGEventSource(stateID: .hidSystemState)
            let cmdKeyCode: CGKeyCode = 0x37
            let vKeyCode: CGKeyCode = 0x09
            let cmdDown = CGEvent(keyboardEventSource: source, virtualKey: cmdKeyCode, keyDown: true)
            let cmdUp = CGEvent(keyboardEventSource: source, virtualKey: cmdKeyCode, keyDown: false)
            let vDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
            let vUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)

            cmdDown?.flags = .maskCommand
            vDown?.flags = .maskCommand
            
            cmdDown?.post(tap: .cghidEventTap)
            vDown?.post(tap: .cghidEventTap)
            vUp?.post(tap: .cghidEventTap)
            cmdUp?.post(tap: .cghidEventTap)
            
            shouldSkipNextUpdate = true
            reset(inserted: true)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pasteboard.clearContents()
                pasteboard.setString(oldValue, forType: .string)
            }
        }
    }
    
    private func updateShouldShow(userInput: AccessibilityUserInput) {
        let manager = AccessibilityNotificationsManager.shared
        let config = Defaults[.typeAheadConfig]
        let inputText = userInput.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        let appName = manager.screenResult.applicationName ?? ""
        let appExcluded = config.excludedApps.contains(where: appName.contains)
        let resumeAt = config.resumeAt ?? .now
        let isResumed = .now >= resumeAt
        
        self.shouldShow = config.isEnabled && !inputText.isEmpty && !appExcluded && isResumed
    }
    
    private func requestCompletion(taskId: UUID) async {
        guard taskId == currentTaskId else { return }
        
        await MainActor.run {
            reset(loading: true)
        }
        
        do {
            var fullCompletion = ""
            let stream = try await Task.detached {
                return try await self.complete()
            }.value
            
            for try await chunk in stream {
                guard taskId == currentTaskId else { return }
                
                fullCompletion += chunk
                
                await MainActor.run {
                    self.completion = fullCompletion
                }
            }
        } catch {
            guard taskId == currentTaskId else { return }
            
            await MainActor.run {
                if let error = error as? TypeAheadError {
                    self.error = error
                } else {
                    self.error = .completionFailed(error.localizedDescription)
                }
                self.completion = ""
            }
        }
        
        if taskId == currentTaskId {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func complete() async throws -> AsyncThrowingStream<String, Error> {
        let config = Defaults[.typeAheadConfig]
        
        guard let model = config.model else {
            throw TypeAheadError.noModelConfigured
        }
        
        let userInput = AccessibilityNotificationsManager.shared.userInput
        guard !userInput.fullText.isEmpty else {
            throw TypeAheadError.noUserInput
        }
        
        // let appName = AccessibilityNotificationsManager.shared.screenResult.applicationName ?? "l'application"
        
        let systemMessage = TypeAheadPrompts.AutoCompletion.systemPrompt
        let instruction = TypeAheadPrompts.AutoCompletion.instruction(userInput: userInput)
        
        if config.streamResponse {
            return try await StreamingClient().localGenerate(
                systemMessage: systemMessage,
                prompt: instruction,
                model: model,
                keepAlive: config.keepAlive,
                options: config.options
            )
        } else {
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        let response = try await FetchingClient().localGenerate(
                            systemMessage: systemMessage,
                            prompt: instruction,
                            model: model,
                            keepAlive: config.keepAlive,
                            options: config.options
                        )
                        continuation.yield(response)
                        continuation.finish()
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
            }
        }
    }
}
