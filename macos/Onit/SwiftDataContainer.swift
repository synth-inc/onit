//
//  SwiftDataContainer.swift
//  Onit
//
//  Created by Kévin Naudin on 10/02/2025.
//

import SwiftData

actor SwiftDataContainer {
    
    @MainActor
    static let appContainer: ModelContainer = {
        do {
            let schema = Schema([
                Chat.self,
                SystemPrompt.self,
            ])
            let container = try! ModelContainer(for: schema)
            
            // Make sure the persistent store is empty. If it's not, return the non-empty container.
            var itemFetchDescriptor = FetchDescriptor<SystemPrompt>()
            itemFetchDescriptor.fetchLimit = 1
            guard try container.mainContext.fetch(itemFetchDescriptor).count == 0 else { return container }
            
            container.mainContext.insert(SystemPrompt.outputOnly)
            try! container.mainContext.save()
            
            return container
        } catch {
            fatalError("Failed to create container")
        }
    }()
    
    @MainActor
    static let inMemoryContainer: () throws -> ModelContainer = {
        let schema = Schema([
            Chat.self,
            SystemPrompt.self,
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schema, configurations: [configuration])
        
        let sampleData: [any PersistentModel] = [
            Chat.sample,
            SystemPrompt.outputOnly
        ]
        sampleData.forEach {
            container.mainContext.insert($0)
        }
        
        return container
    }
}
