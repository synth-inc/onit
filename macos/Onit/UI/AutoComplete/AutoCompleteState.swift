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
    
    private var completionTask: Task<Void, Never>?
    private var debounceTask: Task<Void, Never>?
    
    // MARK: - Initializer
    
    nonisolated init() {
        Task { @MainActor in
            self.startObserving()
        }
    }
    
    // MARK: - Private functions
    
    private func startObserving() {
        Task { @MainActor in
            let manager = AccessibilityNotificationsManager.shared
            
            for await userInput in manager.$userInput.values {
                debounce {
                    await MainActor.run {
                        guard Defaults[.typeAheadConfig].isEnabled else { return }
                        
                        if userInput == .empty {
                            print("\(Date()) : changes detected EMPTY")
                            self.completion = ""
                            self.isLoading = false
                            self.error = nil
                        } else {
                            print("\(Date()) : changes detected \(userInput)")
                            Task.detached {
                                await self.requestCompletion()
                            }
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
            error = nil
        }
        
        completionTask = Task.detached {
            do {
                var fullCompletion = ""
                let stream = try await AutoCompleteService.complete()
                
                for try await chunk in stream {
                    guard !Task.isCancelled else { return }
                    
                    fullCompletion += chunk
                    
                    await MainActor.run {
                        self.completion = fullCompletion
                    }
                }
            } catch let error as AutoCompleteError {
                await MainActor.run {
                    self.error = error
                    self.completion = ""
                }
            } catch {
                await MainActor.run {
                    self.error = .completionFailed(error.localizedDescription)
                    self.completion = ""
                }
            }
            
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func debounce(interval: TimeInterval = 0.3, action: @escaping () async -> Void) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(Int(interval * 1000)))
            guard !Task.isCancelled else { return }
            await action()
        }
    }
}
