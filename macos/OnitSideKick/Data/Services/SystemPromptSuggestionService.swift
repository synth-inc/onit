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
    
    private var frontmostApplicationName: String?
    private var instruction: String = ""
    private var contexts: [Context] = []
    private var input: Input?
    
    private var previousFrontmostApplicationName: String?
    private var previousInstruction: String = ""
    private var previousContexts: [Context] = []
    private var previousInput: Input?
    
    private var processTask: Task<Void, Never>?
    
    init(state: OnitPanelState) {
        self.state = state
        state.addDelegate(self)
        
        if let trackedWindow = state.trackedWindow {
            frontmostApplicationName = trackedWindow.pid.appName
        } else if state.trackedScreen != nil {
            NSWorkspace.shared.publisher(for: \.frontmostApplication)
                .filter { $0?.processIdentifier != getpid() }
                .sink { [weak self] frontmostApplication in
                    guard let self = self else { return }
                    
                    self.frontmostApplicationName = frontmostApplication?.localizedName
                    self.processIfNeeded()
                }
                .store(in: &cancellables)
        }
    }
    
    private func processIfNeeded() {
        if shouldProcess() {
            processTask?.cancel()
            
            updatePreviousValues()
            
            processTask = Task {
                process()
            }
        }
    }
    
    private func shouldProcess() -> Bool {
        guard state.panelOpened && !state.hidden && !state.panelMiniaturized else {
            return false
        }
        
        if frontmostApplicationName != previousFrontmostApplicationName ||
            instruction != previousInstruction ||
            !areContextsEqual(contexts, previousContexts) ||
            input != previousInput {
            
            return true
        }
        
        return false
    }
    
    private func areContextsEqual(_ contexts1: [Context], _ contexts2: [Context]) -> Bool {
        guard contexts1.count == contexts2.count else { return false }
        
        for (index, context1) in contexts1.enumerated() {
            let context2 = contexts2[index]
            switch (context1, context2) {
            case (.auto(let auto1), .auto(let auto2)):
                if auto1 != auto2 {
                    return false
                }
            case (.file(let url1), .file(let url2)):
                if url1 != url2 {
                    return false
                }
            default:
                () // Compare only .auto & .file
            }
        }
        
        return true
    }
    
    private func updatePreviousValues() {
        previousFrontmostApplicationName = frontmostApplicationName
        previousInstruction = instruction
        previousContexts = contexts
        previousInput = input
    }
    
    private func process() {
        guard !Task.isCancelled else { return }
        
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
        
        let frontMostApp = frontmostApplicationName?.lowercased() ?? ""
        
        let text = instruction + " " + inputText + " " + contextListText
        let apps = frontMostApp + " " + inputApp + " " + contextListApp
        
        guard !Task.isCancelled else { return }
        
        updateSuggestions(text: text, apps: apps)
        
        guard !Task.isCancelled else { return }
        
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
        let fetchDescriptor = FetchDescriptor<SystemPrompt>(
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        let allPrompts = (try? state.container.mainContext.fetch(fetchDescriptor)) ?? []
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
    func panelResignKey(state: OnitPanelState) { }
    func panelStateDidChange(state: OnitPanelState) {
        processIfNeeded()
    }
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) {
        self.instruction = instruction
        self.contexts = contexts
        self.input = input
        
        processIfNeeded()
    }
}
