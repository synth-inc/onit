//
//  SystemPromptSuggestionService.swift
//  Onit
//
//  Created by Kévin Naudin on 12/02/2025.
//

import SwiftData
import SwiftUI

class SystemPromptSuggestionService {
    
    struct ScoredPrompt {
        let prompt: SystemPrompt
        let score: Int
    }
    
    private let container: ModelContainer
    
    init(with container: ModelContainer) {
        self.container = container
    }
    
    func findSuggestedPromptIds(input: Input?, contextList: [Context]) async -> [String] {
        let activeApp = NSWorkspace.shared.frontmostApplication?.localizedName?.lowercased()
        let selectedApp = input?.application?.lowercased()
        let selectedText = input?.selectedText.lowercased()
        let contextApps = contextList.compactMap { context -> String? in
            guard case .auto(let appName, _) = context else {
                return nil
            }
            
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
        let allPrompts = (try? context.fetch(FetchDescriptor<SystemPrompt>())) ?? []
        
        let scoredPrompts = allPrompts.map { prompt -> ScoredPrompt in
            var score = 0
            
            for appURL in prompt.applications {
                let lowercaseAppName = appURL.deletingPathExtension().lastPathComponent.lowercased()
                
                if lowercaseAppName == activeApp {
                    score += 5
                }
                if lowercaseAppName == selectedApp {
                    score += 5
                }
                if contextApps.contains(lowercaseAppName) {
                    score += 5
                }
            }
            
            for tag in prompt.tags {
                let lowercaseTag = tag.lowercased()
                
                if selectedText?.contains(lowercaseTag) == true {
                    score += 3
                }
                
                if contextContent.contains(lowercaseTag) {
                    score += 3
                }
            }
            
            return ScoredPrompt(prompt: prompt, score: score)
        }
        
        return scoredPrompts
            .filter { $0.score > 0 }
            .sorted { first, second in
                if first.score == second.score {
                    let date1 = first.prompt.lastUsed ?? first.prompt.timestamp
                    let date2 = second.prompt.lastUsed ?? second.prompt.timestamp
                    return date1 > date2
                }
                return first.score > second.score
            }
            .map { $0.prompt.id }
    }
} 
