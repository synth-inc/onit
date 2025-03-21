//
//  SystemPromptSuggestionService.swift
//  Onit
//
//  Created by Kévin Naudin on 12/02/2025.
//

import Combine
import Defaults
import SwiftData
import SwiftUI

@Observable @MainActor
class SystemPromptSuggestionService {
    private let container: ModelContainer
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var suggestedPrompts: [SystemPrompt] = []
    private var lastPromptUsed: SystemPrompt = .outputOnly
    
    init(model: OnitModel) {
        self.container = model.container

        let instructionPublisher = model.pendingInstructionSubject
            .map { $0.lowercased() }
        let inputTextPublisher = model.pendingInputSubject
            .map { $0?.selectedText.lowercased() ?? "" }
        let contextListTextPublisher = model.pendingContextListSubject
            .map { contexts in
                var temp = ""
                
                for context in contexts {
                    if case .auto(_, let content) = context {
                        temp += content.values.joined(separator: " ").lowercased() + " "
                    } else if case .file(let url) = context {
                        if let contentFile = try? String(contentsOf: url).lowercased() {
                            temp += contentFile + " "
                        }
                    }
                }
                
                return temp
            }
        
        let inputAppPublisher = model.pendingInputSubject
            .map { $0?.application?.lowercased() ?? "" }
        let contextListAppPublisher = model.pendingContextListSubject
            .map { contexts in
                var temp = ""
                
                for context in contexts {
                    if case .auto(let appName, _) = context {
                        temp += appName.lowercased() + " "
                    }
                }
                
                return temp
            }
        
        let frontMostAppPublisher = NSWorkspace.shared.publisher(for: \.frontmostApplication)
            .map { $0?.localizedName?.lowercased() ?? "" }
            .prepend(NSWorkspace.shared.frontmostApplication?.localizedName?.lowercased() ?? "")
        
        let textPublisher = Publishers.CombineLatest3(instructionPublisher, inputTextPublisher, contextListTextPublisher)
            .map { $0 + " " + $1 + " " + $2 }
        let appPublisher = Publishers.CombineLatest3(frontMostAppPublisher, inputAppPublisher, contextListAppPublisher)
            .map { $0 + " " + $1 + " " + $2 }
        
        Publishers.CombineLatest(
            textPublisher,
            appPublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (text, app) in
            guard let self = self else { return }
            self.updateSuggestions(
                text: text,
                apps: app
            )
            
            guard model.currentChat?.systemPrompt == nil && 
                  !SystemPromptState.shared.userSelectedPrompt else { return }
            
            if let firstPrompt = self.suggestedPrompts.first {
                Defaults[.systemPromptId] = firstPrompt.id
                SystemPromptState.shared.shouldShowSystemPrompt = true
            } else {
                Defaults[.systemPromptId] = lastPromptUsed.id
            }
        }
        .store(in: &cancellables)
    }
    
    private func updateSuggestions(
        text: String,
        apps: String
    ) {
        let context = ModelContext(self.container)
        let fetchDescriptor = FetchDescriptor<SystemPrompt>(
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        let allPrompts = (try? context.fetch(fetchDescriptor)) ?? []
        lastPromptUsed = allPrompts.first ?? .outputOnly
        
        let scoredPrompts = allPrompts.map { prompt -> (SystemPrompt, Int) in
            var score = 0
            
            for appURL in prompt.applications {
                let lowercaseAppName = appURL.deletingPathExtension().lastPathComponent.lowercased()
                let appNamePattern = "\\b\(NSRegularExpression.escapedPattern(for: lowercaseAppName))\\b"
            
                if let regex = try? NSRegularExpression(pattern: appNamePattern, options: []) {
                    let range = NSRange(location: 0, length: apps.utf16.count)
                    
                    if regex.firstMatch(in: apps, options: [], range: range) != nil {
                        score += 5
                    }
                }
            }
            
            for tag in prompt.tags {
                let lowercaseTag = tag.lowercased()
                let tagPattern = "\\b\(NSRegularExpression.escapedPattern(for: lowercaseTag))\\b"
                
                if let regex = try? NSRegularExpression(pattern: tagPattern, options: []) {
                    let range = NSRange(location: 0, length: text.utf16.count)
                    
                    if regex.firstMatch(in: text, options: [], range: range) != nil {
                        score += 3
                    }
                }
            }
            
            return (prompt, score)
        }
        
        self.suggestedPrompts = scoredPrompts
            .filter { $0.1 > 0 }
            .sorted { first, second in
                if first.1 == second.1 {
                    let date1 = first.0.lastUsed ?? first.0.timestamp
                    let date2 = second.0.lastUsed ?? second.0.timestamp
                    return date1 > date2
                }
                return first.1 > second.1
            }
            .map { $0.0 }
    }
} 
