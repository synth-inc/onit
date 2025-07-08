//
//  DiffViewModel.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import Foundation
import SwiftData
import Combine

@MainActor
@Observable
class DiffViewModel {
    private let diffChangeManager: DiffChangeManager
    private let response: Response
    
    // Current state
    var diffChanges: [DiffChangeState] = []
    var currentOperationIndex: Int = 0
    var hasUnsavedChanges: Bool = false
    var isPreviewingAllApproved: Bool = false
    
    // Computed properties
    var diffArguments: DiffTool.PlainTextDiffArguments? {
        response.diffArguments
    }
    
    var diffResult: DiffTool.PlainTextDiffResult? {
        response.diffResult
    }
    
    var currentOperation: DiffTool.PlainTextDiffOperation? {
        guard let result = diffResult,
              currentOperationIndex < result.operations.count else { return nil }
        return result.operations[currentOperationIndex]
    }
    
    var currentDiffChange: DiffChangeState? {
        diffChanges.first { $0.operationIndex == currentOperationIndex }
    }
    
    var statistics: (pending: Int, approved: Int, rejected: Int) {
        diffChangeManager.getChangeStatistics(for: response)
    }
    
    var canNavigateNext: Bool {
        guard let result = diffResult else { return false }
        return currentOperationIndex < result.operations.count - 1
    }
    
    var canNavigatePrevious: Bool {
        return currentOperationIndex > 0
    }
    
    var allChangesApproved: Bool {
        let stats = statistics
        return stats.pending == 0 && stats.approved > 0
    }
    
    init(response: Response, modelContext: ModelContext) {
        self.response = response
        self.diffChangeManager = DiffChangeManager(modelContext: modelContext)
        loadOrCreateDiffChanges()
    }
    
    // MARK: - Data Management
    
    private func loadOrCreateDiffChanges() {
        diffChanges = diffChangeManager.getDiffChanges(for: response)
        
        if diffChanges.isEmpty {
            diffChangeManager.createOrUpdateDiffChanges(for: response)
            diffChanges = diffChangeManager.getDiffChanges(for: response)
        }
        
        if let firstPending = diffChanges.first(where: { $0.status == .pending }) {
            currentOperationIndex = firstPending.operationIndex
        }
    }
    
    // MARK: - Actions
    
    func approveCurrentChange() {
        updateCurrentChangeStatus(.approved)
    }
    
    func rejectCurrentChange() {
        updateCurrentChangeStatus(.rejected)
    }
    
    func approveAllChanges() {
        diffChangeManager.approveAllChanges(for: response)
        refreshChanges()
        hasUnsavedChanges = true
    }
    
    func rejectAllChanges() {
        diffChangeManager.rejectAllChanges(for: response)
        refreshChanges()
    }
    
    private func updateCurrentChangeStatus(_ status: DiffChangeStatus) {
        diffChangeManager.updateDiffChangeStatus(
            response: response,
            operationIndex: currentOperationIndex,
            status: status
        )
        refreshChanges()
        
        if status == .approved {
            hasUnsavedChanges = true
        }
        
        navigateToNextPendingChange()
    }
    
    // MARK: - Navigation
    
    func navigateNext() {
        guard canNavigateNext else { return }
        currentOperationIndex += 1
    }
    
    func navigatePrevious() {
        guard canNavigatePrevious else { return }
        currentOperationIndex -= 1
    }
    
    func navigateToNextPendingChange() {
        guard let nextPending = diffChangeManager.getNextPendingChange(
                for: response,
                after: currentOperationIndex
              ) else { return }
        
        currentOperationIndex = nextPending.operationIndex
    }
    
    func navigateToPreviousPendingChange() {
        guard let previousPending = diffChangeManager.getPreviousPendingChange(
                for: response,
                before: currentOperationIndex
              ) else { return }
        
        currentOperationIndex = previousPending.operationIndex
    }
    
    // MARK: - Text Generation
    
    func generatePreviewText() -> String {
        guard let arguments = diffArguments,
              let result = diffResult else { return "" }
        
        let effectiveChanges = getEffectiveDiffChanges()
        let approvedOperationIndices = Set(effectiveChanges.filter { $0.status == .approved }.map { $0.operationIndex })
        
        var text = arguments.original_content
        var offset = 0
        
        for (index, operation) in result.operations.enumerated() {
            guard approvedOperationIndices.contains(index) else { continue }
            
            switch operation.type {
            case "insertText":
                if let insertIndex = operation.index,
                   let newText = operation.text {
                    let adjustedIndex = insertIndex + offset
                    if adjustedIndex <= text.count {
                        let index = text.index(text.startIndex, offsetBy: adjustedIndex)
                        text.insert(contentsOf: newText, at: index)
                        offset += newText.count
                    }
                }
                
            case "deleteContentRange":
                if let startIndex = operation.startIndex,
                   let endIndex = operation.endIndex {
                    let adjustedStart = startIndex + offset
                    let adjustedEnd = endIndex + offset
                    if adjustedStart < text.count && adjustedEnd <= text.count && adjustedStart <= adjustedEnd {
                        let start = text.index(text.startIndex, offsetBy: adjustedStart)
                        let end = text.index(text.startIndex, offsetBy: adjustedEnd)
                        let deletedLength = adjustedEnd - adjustedStart
                        text.removeSubrange(start..<end)
                        offset -= deletedLength
                    }
                }
                
            case "replaceText":
                if let startIndex = operation.startIndex,
                   let endIndex = operation.endIndex,
                   let newText = operation.newText {
                    let adjustedStart = startIndex + offset
                    let adjustedEnd = endIndex + offset
                    if adjustedStart < text.count && adjustedEnd <= text.count && adjustedStart <= adjustedEnd {
                        let start = text.index(text.startIndex, offsetBy: adjustedStart)
                        let end = text.index(text.startIndex, offsetBy: adjustedEnd)
                        let originalLength = adjustedEnd - adjustedStart
                        text.replaceSubrange(start..<end, with: newText)
                        offset += newText.count - originalLength
                    }
                }
                
            default:
                break
            }
        }
        
        return text
    }
    
    func markAsSaved() {
        hasUnsavedChanges = false
    }
    
    // MARK: - Preview Mode
    
    func startPreviewingAllApproved() {
        isPreviewingAllApproved = true
    }
    
    func stopPreviewingAllApproved() {
        isPreviewingAllApproved = false
    }
    
    func getEffectiveDiffChanges() -> [DiffChangeState] {
        if isPreviewingAllApproved {
            return diffChanges.map { change in
                let previewChange = DiffChangeState(
                    responseId: change.responseId,
                    operationIndex: change.operationIndex,
                    operationType: change.operationType,
                    status: change.status == .pending ? .approved : change.status,
                    operationText: change.operationText,
                    operationStartIndex: change.operationStartIndex,
                    operationEndIndex: change.operationEndIndex
                )
                return previewChange
            }
        } else {
            return diffChanges
        }
    }
    
    // MARK: - Private
    
    private func refreshChanges() {
        diffChanges = diffChangeManager.getDiffChanges(for: response)
    }
} 