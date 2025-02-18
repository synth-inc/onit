//
//  AutoCompleteState.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import Defaults
import SwiftUI

@Observable
@MainActor
final class AutoCompleteState {
    
    // MARK: - Singleton instance
    
    @MainActor
    static let shared = AutoCompleteState()
    
    // MARK: - Properties
    
    var completion: String = ""
    var isLoading = false
    var error: AutoCompleteError?
    
    private var currentTaskId: UUID?
    
    // MARK: - Initializer
    
    nonisolated init() {
        Task { @MainActor in
            self.startObserving()
        }
    }
    
    // MARK: - Functions
    
    func insertSuggestion() {
        if !isLoading && !completion.isEmpty {
            // Copy/Paste trick
            let pasteboard = NSPasteboard.general
            let oldValue = pasteboard.string(forType: .string) ?? ""
            
            pasteboard.clearContents()
            pasteboard.setString(completion, forType: .string)

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
            
            completion = ""
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pasteboard.clearContents()
                pasteboard.setString(oldValue, forType: .string)
            
                // reset input to not trigger the autocomplete again
                AccessibilityNotificationsManager.shared.resetInput()
            }
        }
    }
    
    // MARK: - Private functions
    
    private func startObserving() {
        Task { @MainActor in
            let manager = AccessibilityNotificationsManager.shared
            
            for try await userInput in manager.$userInput.values {
                Task { @MainActor in
                    let taskId = UUID()
                    self.currentTaskId = taskId
                    
                    guard Defaults[.typeAheadConfig].isEnabled else { return }
                    
                    if userInput.precedingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        self.completion = ""
                        self.isLoading = false
                        self.error = nil
                        
                        return
                    }
                    
                    await self.requestCompletion(taskId: taskId)
                }
            }
        }
    }
    
    private func requestCompletion(taskId: UUID) async {
        guard taskId == currentTaskId else { return }
        
        await MainActor.run {
            self.isLoading = true
            self.error = nil
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
                if let autoCompleteError = error as? AutoCompleteError {
                    self.error = autoCompleteError
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
            throw AutoCompleteError.noModelConfigured
        }
        
        let userInput = AccessibilityNotificationsManager.shared.userInput
        guard !userInput.fullText.isEmpty else {
            throw AutoCompleteError.noUserInput
        }
        
        // let appName = AccessibilityNotificationsManager.shared.screenResult.applicationName ?? "l'application"
        
        let systemMessage = systemPrompt()
        let instruction = userPrompt(userInput: userInput)
        
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
    
    private func systemPrompt() -> String {
        return """
You are a text completion AI. Complete words and phrases directly.

CRITICAL RULES:
1. Start your completion immediately without ...,
2. NEVER repeat text before [COMPLETE HERE]
3. Maximum 20 characters
4. Keep suggestions natural and contextual
5. NO explanations, NO dots, NO quotes

BAD EXAMPLES:
Input: "I am writ[COMPLETE HERE]"
❌ "...ing"
❌ " ing"
❌ "I am writing"

GOOD EXAMPLES:
Input: "I am writ[COMPLETE HERE]"
✅ ing a letter

Input: "The meet[COMPLETE HERE] at 2pm"
✅ ing starts

Input: "Je vais au rest[COMPLETE HERE]"
✅ aurant
"""
    }
    
    private func userPrompt(userInput: AccessibilityUserInput) -> String {
        return """
Complete directly after the cursor:
\(userInput.precedingText)[COMPLETE HERE]\(userInput.followingText)
"""
    }
}
