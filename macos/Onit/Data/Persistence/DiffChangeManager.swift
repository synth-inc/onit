//
//  DiffChangeManager.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import Foundation
import SwiftData

@MainActor
class DiffChangeManager: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // MARK: - Queries
    
    func getDiffChanges(for response: Response) -> [DiffChangeState] {
        let contextToUse = response.modelContext ?? modelContext

        return getDiffChanges(for: response, using: contextToUse)
    }
    
    private func getDiffChanges(for response: Response, using context: ModelContext) -> [DiffChangeState] {
        let responseId = response.persistentModelID.stableID
        let descriptor = FetchDescriptor<DiffChangeState>(
            predicate: #Predicate { $0.responseId == responseId },
            sortBy: [SortDescriptor(\.operationIndex)]
        )
        
        do {
            let results = try context.fetch(descriptor)
            return results
        } catch {
            print("Error fetching diff changes: \(error)")
            return []
        }
    }
    
    func getDiffChange(for response: Response, operationIndex: Int) -> DiffChangeState? {
        let responseId = response.persistentModelID.stableID
        let descriptor = FetchDescriptor<DiffChangeState>(
            predicate: #Predicate { $0.responseId == responseId && $0.operationIndex == operationIndex }
        )
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            print("Error fetching diff change: \(error)")
            return nil
        }
    }
    
    // MARK: - Create/Update
    
    func createOrUpdateDiffChanges(for response: Response) {
        guard let responseContext = response.modelContext,
			  let diffResult = response.diffResult else {
            return
        }
        
        let responseId = response.persistentModelID.stableID
        let descriptor = FetchDescriptor<DiffChangeState>(
            predicate: #Predicate { $0.responseId == responseId },
            sortBy: [SortDescriptor(\.operationIndex)]
        )
        
        do {
            let existingChanges = try responseContext.fetch(descriptor)
            for change in existingChanges {
                responseContext.delete(change)
            }
        } catch {
            print("Error fetching existing changes: \(error)")
        }
        
        for (index, operation) in diffResult.operations.enumerated() {
            let diffChange = DiffChangeState(
                responseId: response.persistentModelID.stableID,
                operationIndex: index,
                operationType: operation.type,
                status: .pending,
                operationText: operation.text ?? operation.newText,
                operationStartIndex: operation.startIndex ?? operation.index,
                operationEndIndex: operation.endIndex
            )
            responseContext.insert(diffChange)
        }
        
		saveContext(responseContext)
    }
    
    func updateDiffChangeStatus(response: Response, operationIndex: Int, status: DiffChangeStatus) {
        if let diffChange = getDiffChange(for: response, operationIndex: operationIndex) {
            diffChange.status = status
            diffChange.timestamp = Date()
            saveContext(response.modelContext ?? modelContext)
        }
    }
    
    func approveAllChanges(for response: Response) {
        let changes = getDiffChanges(for: response)
        for change in changes {
            change.status = .approved
            change.timestamp = Date()
        }
        saveContext(response.modelContext ?? modelContext)
    }
    
    func rejectAllChanges(for response: Response) {
        let changes = getDiffChanges(for: response)
        for change in changes {
            change.status = .rejected
            change.timestamp = Date()
        }
        saveContext(response.modelContext ?? modelContext)
    }
    
    // MARK: - Statistics
    
    func getChangeStatistics(for response: Response) -> (pending: Int, approved: Int, rejected: Int) {
        let changes = getDiffChanges(for: response)
        
        let pending = changes.filter { $0.status == .pending }.count
        let approved = changes.filter { $0.status == .approved }.count
        let rejected = changes.filter { $0.status == .rejected }.count
        
        return (pending: pending, approved: approved, rejected: rejected)
    }
    
    // MARK: - Navigation
    
    func getNextPendingChange(for response: Response, after currentIndex: Int) -> DiffChangeState? {
        let changes = getDiffChanges(for: response)
            .filter { $0.status == .pending && $0.operationIndex > currentIndex }
        return changes.first
    }
    
    func getPreviousPendingChange(for response: Response, before currentIndex: Int) -> DiffChangeState? {
        let changes = getDiffChanges(for: response)
            .filter { $0.status == .pending && $0.operationIndex < currentIndex }
        return changes.last
    }
    
    // MARK: - Private
    
    private func saveContext(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("Error saving diff changes: \(error)")
        }
    }
} 