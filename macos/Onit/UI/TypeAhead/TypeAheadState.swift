//
//  TypeAheadState.swift
//  Onit
//
//  Created by Kévin Naudin on 13/02/2025.
//

import Defaults
import SwiftData
import SwiftUI

@Observable
@MainActor
final class TypeAheadState {
    
    // MARK: - Singleton instance
    
    @MainActor
    static let shared = TypeAheadState()
    
    // MARK: - Properties
    
    var request: Request?
    var isLoading = false
    var error: TypeAheadError?
    var isCompletionInserted = false
    
    var showMenu = false
    
    private(set) var shouldShow: Bool = false
    
    private let moreSuggestionsState = TypeAheadMoreSuggestionsState.shared
    private var shouldSkipNextUpdate: Bool = false
    
    private var requestQueue = RequestQueue()
    
    struct Request {
        let input: AccessibilityUserInput
        let screenResult: ScreenResult
        var completion: String = ""
    }
    
    // MARK: - Initializer
    
    private init() {
        startObservingUserInput()
        startObservingScreenResult()
    }
    
    // MARK: - Functions
    
    func insertSuggestion() {
        guard let request = request else { return }
        
        if let hoveredIndex = moreSuggestionsState.hoveredIndex,
           hoveredIndex < moreSuggestionsState.moreSuggestions.count {
            var request = request
            request.completion = moreSuggestionsState.moreSuggestions[hoveredIndex]
            insertSuggestion(request: request)
        } else {
            insertSuggestion(request: request)
        }
    }
    
    // MARK: - Private functions
    
    private func insertSuggestion(request: Request) {
        if !isLoading && !request.completion.isEmpty {
            // Copy/Paste trick
            let pasteboard = NSPasteboard.general
            let oldValue = pasteboard.string(forType: .string) ?? ""
            
            pasteboard.clearContents()
            pasteboard.setString(request.completion, forType: .string)

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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pasteboard.clearContents()
                pasteboard.setString(oldValue, forType: .string)
            }
            
            Task {
                await TypeaheadLearningService.shared.updateCase(
                    with: request.completion,
                    input: request.input,
                    screenResult: request.screenResult
                )
            }
            
            shouldSkipNextUpdate = true
            reset(inserted: true)
        }
    }
    
    private func reset(loading: Bool = false, inserted: Bool = false) {
        request = nil
        isLoading = loading
        error = nil
        isCompletionInserted = inserted
        
        moreSuggestionsState.reset()
    }
    
    private func updateShouldShow(request: Request) {
        let config = Defaults[.typeaheadConfig]
        let inputText = request.input.fullText.trimmingCharacters(in: .whitespacesAndNewlines)
        let appName = request.screenResult.applicationName ?? ""
        let appExcluded = config.excludedApps.contains(where: appName.contains)
        let resumeAt = config.resumeAt ?? .now
        let isResumed = .now >= resumeAt
        
        self.shouldShow = config.isEnabled && !inputText.isEmpty && !appExcluded && isResumed
    }
    
    private func startObservingUserInput() {
        Task { @MainActor in
            let manager = AccessibilityNotificationsManager.shared
            
            for try await userInput in manager.$userInput.values {
                let request = Request(input: userInput, screenResult: manager.screenResult)
                
                await handleUserInputChange(request)
            }
        }
    }
    
    private func startObservingScreenResult() {
        Task { @MainActor in
            let manager = AccessibilityNotificationsManager.shared
            var previousAppName: String?
            var previousAppTitle: String?
            
            for try await screenResult in manager.$screenResult.values {
                let currentAppName = screenResult.applicationName
                let currentAppTitle = screenResult.applicationTitle
                
                if currentAppName != previousAppName || currentAppTitle != previousAppTitle {
                    previousAppName = currentAppName
                    previousAppTitle = currentAppTitle
                    
                    await requestQueue.cancelAll()
                    shouldShow = false
                    reset()
                }
            }
        }
    }
    
    private func handleUserInputChange(_ request: Request) async {
        await requestQueue.cancelAll()
        
        updateShouldShow(request: request)
        
        guard shouldShow else {
            reset()
            return
        }
        
        if shouldSkipNextUpdate {
            shouldSkipNextUpdate = false
            return
        }
        
        await requestQueue.enqueue {
            await self.requestCompletion(request: request)
        }
    }
    
    private func requestCompletion(request: Request) async {
        await MainActor.run {
            reset(loading: true)
        }
        
        do {
            let config = Defaults[.typeaheadConfig]
            guard let model = config.model else {
                throw TypeAheadError.noModelConfigured
            }
            
            var fullCompletion = ""
            
            let stream = try await TypeaheadAutocompletionService.shared.generateSuggestion(
                userInput: request.input,
                screenResult: request.screenResult,
                model: model,
                config: config
            )
            
            self.request = request
            
            for try await chunk in stream {
                guard await !requestQueue.isCancelled else { return }
                
                fullCompletion += chunk
                
                await MainActor.run {
                    self.request?.completion = fullCompletion
                }
            }
        } catch {
            guard await !requestQueue.isCancelled else { return }
            
            await MainActor.run {
                if let error = error as? TypeAheadError {
                    self.error = error
                } else {
                    self.error = .completionFailed(error.localizedDescription)
                }
                self.request = nil
            }
        }
        
        guard await !requestQueue.isCancelled else { return }
        
        await MainActor.run {
            self.isLoading = false
        }
    }
}

private actor RequestQueue {
    var isCancelled = false
    private var currentTask: Task<Void, Never>?
    
    func enqueue(_ operation: @MainActor @escaping () async -> Void) {
        cancelAll()
        
        isCancelled = false
        currentTask = Task { @MainActor in
            await operation()
        }
    }
    
    func cancelAll() {
        isCancelled = true
        currentTask?.cancel()
        currentTask = nil
    }
}
