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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                pasteboard.clearContents()
                pasteboard.setString(oldValue, forType: .string)
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
        guard userInput != .empty else {
            throw AutoCompleteError.noUserInput
        }
        
        let appName = AccessibilityNotificationsManager.shared.screenResult.applicationName ?? "l'application"
        
        let systemMessage = """
        You are an auto-completion assistant specialized in text prediction.
        
        IMPORTANT RULES:
        1. NEVER repeat the already typed text
        2. ONLY provide the logical continuation of the text
        3. Stay concise and natural
        4. Respect style and context
        5. Answer in a single line
        6. Do not add punctuation at the beginning
        """
        
        let instruction = """
        TEXT TO COMPLETE:
        
        Before cursor: "\(userInput.precedingText)"
        [CURSOR HERE]
        After cursor: "\(userInput.followingText)"
        
        Complete the text from the cursor position.
        """
        
        let instructions = [instruction]
        let inputs: [Input?] = [nil]
        let files: [[URL]] = [[]]
        let images: [[URL]] = [[]]
        let autoContexts: [[String: String]] = [[:]]
        let responses: [String] = []
        
        if config.streamResponse {
            return try await StreamingClient().localChat(
                systemMessage: systemMessage,
                instructions: instructions,
                inputs: inputs,
                files: files,
                images: images,
                autoContexts: autoContexts,
                responses: responses,
                model: model,
                options: config.options
            )
        } else {
            return AsyncThrowingStream { continuation in
                Task {
                    do {
                        let response = try await FetchingClient().localChat(
                            systemMessage: systemMessage,
                            instructions: instructions,
                            inputs: inputs,
                            files: files,
                            images: images,
                            autoContexts: autoContexts,
                            responses: responses,
                            model: model,
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
