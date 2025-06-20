//
//  SwiftDataContainer.swift
//  Onit
//
//  Created by Kévin Naudin on 10/02/2025.
//

import SwiftData
import Defaults

actor SwiftDataContainer {
    
    @MainActor
    static let appContainer: ModelContainer = {
        do {
            let schema = Schema([
                Chat.self,
                SystemPrompt.self,
            ])
                        
            let container = try ModelContainer(for: schema) // , migrationPlan: migrationPlan)
            maybeUpdatePromptPriorInstructions(container: container)
            
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
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        maybeUpdatePromptPriorInstructions(container: container)

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
            print("Error updating prior instructions: \(error)")
        }
    }
}
