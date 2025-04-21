//
//  SystemPromptSuggestionService.swift
//  Onit
//
//  Created by Kévin Naudin on 12/02/2025.
//

import Combine
import SwiftData
import SwiftUI

@Observable @MainActor
class SystemPromptSuggestionService {
    private let state: OnitPanelState
    private var cancellables = Set<AnyCancellable>()
    
    private(set) var suggestedPrompts: [SystemPrompt] = []
    private var lastPromptUsed: SystemPrompt = .outputOnly
    
    private var instruction: String = ""
    private var contexts: [Context] = []
    private var input: Input?
    private var frontmostApplication: NSRunningApplication?
    
    init(state: OnitPanelState) {
        self.state = state
        state.addDelegate(self)
        
        NSWorkspace.shared.publisher(for: \.frontmostApplication)
            .sink { [weak self] frontmostApplication in
                guard let self = self else { return }
                
                self.frontmostApplication = frontmostApplication
                self.process()
            }
            .store(in: &cancellables)
    }
    
    private func process() {
        let instruction = instruction.lowercased()
        let inputText = input?.selectedText.lowercased() ?? ""
        
        var contextListText = ""
        for context in contexts {
            if case .auto(let autoContext) = context {
                contextListText += autoContext.appContent.values.joined(separator: " ").lowercased() + " "
            } else if case .file(let url) = context {
                if let contentFile = try? String(contentsOf: url).lowercased() {
                    contextListText += contentFile + " "
                }
            }
        }
        
        let inputApp = input?.application?.lowercased() ?? ""
        var contextListApp = ""
        for context in contexts {
            if case .auto(let autoContext) = context {
                contextListApp += autoContext.appName.lowercased() + " "
            }
        }
        
        let frontMostApp = frontmostApplication?.localizedName?.lowercased() ?? ""
        
        let text = instruction + " " + inputText + " " + contextListText
        let apps = frontMostApp + " " + inputApp + " " + contextListApp
        
        updateSuggestions(text: text, apps: apps)
        
        guard state.currentChat?.systemPrompt == nil &&
                !state.systemPromptState.userSelectedPrompt else { return }

        if let firstPrompt = self.suggestedPrompts.first {
            state.systemPromptId = firstPrompt.id
            state.systemPromptState.shouldShowSystemPrompt = true
        } else {
            state.systemPromptId = lastPromptUsed.id
        }
    }
    
    private func updateSuggestions(text: String, apps: String) {
        let context = ModelContext(state.container)
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

extension SystemPromptSuggestionService: OnitPanelStateDelegate {
    func panelBecomeKey(state: OnitPanelState) { }
    func panelStateDidChange(state: OnitPanelState) { }
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) {
        self.instruction = instruction
        self.contexts = contexts
        self.input = input
        
        process()
    }
}
