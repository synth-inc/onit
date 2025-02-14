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
    
    private var completionTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    
    var text: String = "" {
        didSet {
            guard Defaults[.typeAheadConfig].isEnabled else { return }
            
            if text.isEmpty {
                completion = ""
                isLoading = false
            } else {
                Task.detached {
                    await self.requestCompletion()
                }
            }
        }
    }
    
    // MARK: - Initializer
    
    nonisolated init() {
        Task { @MainActor in
            self.startObserving()
        }
    }
    
    // MARK: - Private functions
    
    private func debounce(interval: TimeInterval = 0.3, action: @escaping () async -> Void) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
            guard !Task.isCancelled else { return }
            await action()
        }
    }
    
    private func startObserving() {
        Task { @MainActor in
            let manager = AccessibilityNotificationsManager.shared
        
            for await screenResult in manager.$screenResult.values {
                if let userInput = screenResult.userInteraction.input {
                    debounce {
                        await MainActor.run {
                            self.text = userInput
                        }
                    }
                }
            }
        }
    }
    
    private func requestCompletion() async {
        await MainActor.run {
            completionTask?.cancel()
            
            isLoading = true
        }
        
        completionTask = Task.detached { [text] in
            do {
                var fullCompletion = ""
                let stream = try await AutoCompleteService.complete(text: text)
                
                for try await chunk in stream {
                    guard !Task.isCancelled else { return }
                    
                    fullCompletion += chunk
                    
                    await MainActor.run {
                        self.completion = fullCompletion
                    }
                }
            } catch {
                print("Auto-completion error: \(error)")
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
}
