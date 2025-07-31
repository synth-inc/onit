//
//  SwiftDataContainer.swift
//  Onit
//
//  Created by Kévin Naudin on 10/02/2025.
//

import SwiftData
import Defaults
import Foundation

actor SwiftDataContainer {
    
    @MainActor
    static let appContainer: ModelContainer = {
        do {
            let schema = Schema([
                Chat.self,
                SystemPrompt.self,
                Prompt.self,
                Response.self,
                DiffChangeState.self,
                DiffRevision.self,
            ])
            
            // This handles legacy clients before we added the sandbox entitlement. 
            // Their data will be stored in the public ~/Library/Application Support/default.store, 
            // which is accessible to other apps. This function copies that data to a new, private location.
            DatabaseMigrationService.shared.performMigrationIfNeeded()
            
            // Create container with default secure storage (sandboxed location)
            var configurations : [ModelConfiguration] = []
            if let secureStorageURL = DatabaseMigrationService.shared.getSecureStorageURL() {
                configurations.append(ModelConfiguration(url: secureStorageURL))
            }
            let container = try ModelContainer(for: schema, configurations: configurations)
                
            maybeUpdatePromptPriorInstructions(container: container)
            maybeCleanupHangingPromptReferences(container: container)
            
                let itemFetchDescriptor = FetchDescriptor<SystemPrompt>()
            let existingPrompts = try container.mainContext.fetch(itemFetchDescriptor)
            
            if existingPrompts.isEmpty {
                container.mainContext.insert(SystemPrompt.outputOnly)
                try container.mainContext.save()
            }
            
            return container
        } catch {
            fatalError("Failed to create container \(error)")
        }
    }()
    
    @MainActor
    static let inMemoryContainer: () throws -> ModelContainer = {
        let schema = Schema([
            Chat.self,
            SystemPrompt.self,
            Prompt.self,
            Response.self,
            DiffChangeState.self,
            DiffRevision.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        maybeUpdatePromptPriorInstructions(container: container)
        maybeCleanupHangingPromptReferences(container: container)

        let sampleData: [any PersistentModel] = [
            Chat.sample,
            SystemPrompt.outputOnly
        ]
        sampleData.forEach {
            container.mainContext.insert($0)
        }
        
        return container
    }
    
    @MainActor
    // This function moves the instruction to the response object, which is needed to allow for editing the instruction in a prompt you've already sent once.
    static func maybeUpdatePromptPriorInstructions(container: ModelContainer) {
        // Check if migration has already been performed
        guard !Defaults[.hasPerformedInstructionResponseMigration] else { return }
        
        let context = container.mainContext
        let promptDescriptor = FetchDescriptor<Prompt>()
        do {
            let prompts = try context.fetch(promptDescriptor)
            for prompt in prompts {                
                // Update each response's instruction field
                for response in prompt.responses {
                    response.instruction = prompt.instruction
                }
            }
            
            try context.save()
            // Mark migration as performed
            Defaults[.hasPerformedInstructionResponseMigration] = true
        } catch {
            print("SwiftDataContainer - Error updating prior instructions: \(error)")
        }
    }
    
    @MainActor
    static func maybeCleanupHangingPromptReferences(container: ModelContainer) {
        // Check if migration has already been performed
        guard Defaults[.needsHangingPromptCleanup] else { return }
        
        let context = container.mainContext
        
        do {
            // Instead of trying to detect invalid references (which causes fatal errors),
            // we'll rebuild all prompt chains from scratch based on chat membership and timestamps
            let chatDescriptor = FetchDescriptor<Chat>()
            let chats = try context.fetch(chatDescriptor)
            
            var cleanupCount = 0
            
            // First pass builds a look up table of valid ids.
            var validPromptIds : [PersistentIdentifier] = []
            for chat in chats {
                let prompts = chat.prompts.sorted { $0.timestamp < $1.timestamp }
                for prompt in prompts {
                    validPromptIds.append(prompt.persistentModelID)
                }
            }

            for chat in chats {
                // Clear all existing chain references (some may be invalid)
                let prompts = chat.prompts.sorted { $0.timestamp < $1.timestamp }
                var foundInvalid = false
                for prompt in prompts {
                    if let priorPromptId = prompt.priorPrompt?.persistentModelID {
                        if !validPromptIds.contains(priorPromptId) {
                            foundInvalid = true
                            break
                        }
                    }
                    if let nextPromptId = prompt.nextPrompt?.persistentModelID {
                        if !validPromptIds.contains(nextPromptId) {
                            foundInvalid = true
                            break
                        }
                    }
                }
                
                if foundInvalid {
                    // Rebuild the chain based on timestamp order
                    for (index, prompt) in prompts.enumerated() {
                        // Set prior prompt if this isn't the first prompt
                        if index == 0 {
                            prompt.priorPrompt = nil
                        }
                        if index > 0 {
                            prompt.priorPrompt = prompts[index - 1]
                        }
                        // Set next prompt if this isn't the last prompt
                        if index < prompts.count - 1 {
                            prompt.nextPrompt = prompts[index + 1]
                        }
                        if index == prompts.count - 1 {
                            prompt.nextPrompt = nil
                        }
                    }
                    cleanupCount += 1
                }
            }
            
            if cleanupCount > 0 {
                do {
                    try context.save()
                } catch {
                    print("SwiftDataContainer - Error saving after prompt chain cleanup: \(error)")
                }
                print("SwiftDataContainer - Rebuilt prompt chains for \(cleanupCount) chats")
            }
        } catch {
            print("SwiftDataContainer - Error during hanging prompt cleanup migration: \(error)")
        }   
        Defaults[.needsHangingPromptCleanup] = false
    }
}


