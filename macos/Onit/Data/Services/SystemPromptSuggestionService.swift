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

        let inputPublisher = Optional.Publisher(model.pendingInput)
            .prepend(model.pendingInput)
            .eraseToAnyPublisher()
        let contextListPublisher = Timer.publish(every: 0.3, on: .main, in: .common)
            .autoconnect()
            .map { _ in model.pendingContextList }
            .removeDuplicates()
            .prepend(model.pendingContextList)
        let frontMostAppPublisher = NSWorkspace.shared.publisher(for: \.frontmostApplication)
            .map { $0?.localizedName?.lowercased() ?? "" }
            .prepend(NSWorkspace.shared.frontmostApplication?.localizedName?.lowercased() ?? "")
        
        Publishers.CombineLatest3(
            inputPublisher,
            contextListPublisher,
            frontMostAppPublisher
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] (input, contextList, activeApp) in
            guard let self = self else { return }
            self.updateSuggestions(
                input: input,
                contextList: contextList,
                activeApp: activeApp
            )
            
            guard model.currentChat?.systemPrompt == nil else { return }
            
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
        input: Input?,
        contextList: [Context],
        activeApp: String?
    ) {
        let selectedApp = input?.application?.lowercased()
        let selectedText = input?.selectedText.lowercased()
        let contextApps = contextList.compactMap { context -> String? in
            guard case .auto(let appName, _) = context else { return nil }
            return appName.lowercased()
        }
        
        let contextContent = contextList.compactMap { context -> String? in
            switch context {
            case .auto(_, let content):
                return content.values.joined(separator: " ").lowercased()
            case .file(let url):
                return try? String(contentsOf: url).lowercased()
            default:
                return nil
            }
        }.joined(separator: " ")
        
        let context = ModelContext(self.container)
        var fetchDescriptor = FetchDescriptor<SystemPrompt>(
            sortBy: [SortDescriptor(\.lastUsed, order: .reverse)]
        )
        let allPrompts = (try? context.fetch(fetchDescriptor)) ?? []
        lastPromptUsed = allPrompts.first ?? .outputOnly
        
        let scoredPrompts = allPrompts.map { prompt -> (SystemPrompt, Int) in
            var score = 0
            
            for appURL in prompt.applications {
                let lowercaseAppName = appURL.deletingPathExtension().lastPathComponent.lowercased()
                
                if lowercaseAppName == activeApp { score += 5 }
                if lowercaseAppName == selectedApp { score += 5 }
                if contextApps.contains(lowercaseAppName) { score += 5 }
            }
            
            for tag in prompt.tags {
                let lowercaseTag = tag.lowercased()
                if selectedText?.contains(lowercaseTag) == true { score += 3 }
                if contextContent.contains(lowercaseTag) { score += 3 }
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
