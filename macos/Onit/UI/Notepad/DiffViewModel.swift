//
//  DiffViewModel.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import AppKit
import Combine
import Foundation
import SwiftData

@MainActor
@Observable
class DiffViewModel {
    private let modelContext: ModelContext
    let response: Response
    
    // Current state
    var diffChanges: [DiffChangeState] = []
    var currentOperationIndex: Int = 0
    var hasUnsavedChanges: Bool = false
    var isPreviewingAllApproved: Bool = false
    var isInserting: Bool = false
    var insertionError: String? = nil
    
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
        getChangeStatistics()
    }
    
    var canNavigateNext: Bool {
        return getNextPendingChange(after: currentOperationIndex) != nil
    }
    
    var canNavigatePrevious: Bool {
        return getPreviousPendingChange(before: currentOperationIndex) != nil
    }
    
    var allChangesApproved: Bool {
        let stats = statistics
        return stats.pending == 0 && stats.approved > 0
    }
    
    var totalPendingOperationsCount: Int {
        return diffChanges.filter { $0.status == .pending }.count
    }
    
    var currentPendingOperationNumber: Int {
        let pendingChanges = diffChanges.filter { $0.status == .pending }
            .sorted { $0.operationIndex < $1.operationIndex }
        
        if let currentIndex = pendingChanges.firstIndex(where: { $0.operationIndex == currentOperationIndex }) {
            return currentIndex + 1
        }
        return 1
    }
    
    init(response: Response) {
        self.response = response
        self.modelContext = SwiftDataContainer.appContainer.mainContext
        
        loadOrCreateDiffChanges()
    }
    
    func refreshForResponseUpdate() {
        let hadChanges = !diffChanges.isEmpty
        
        loadOrCreateDiffChanges()
        
        if hadChanges && !diffChanges.isEmpty {
            if currentOperationIndex >= diffChanges.count {
                if let firstPending = diffChanges.first(where: { $0.status == .pending }) {
                    currentOperationIndex = firstPending.operationIndex
                }
            }
        }
    }
    
    func refreshForRevisionChange() {
        diffChanges = getDiffChanges()
        
        if let firstPending = diffChanges.first(where: { $0.status == .pending }) {
            currentOperationIndex = firstPending.operationIndex
        } else {
            currentOperationIndex = 0
        }
        
        isPreviewingAllApproved = false
    }
    
    // MARK: - Data Management
    
    private func loadOrCreateDiffChanges() {
        diffChanges = getDiffChanges()
        
        if response.isPartial {
            if diffChanges.isEmpty && response.diffResult != nil {
                createDiffChanges()
                diffChanges = getDiffChanges()
            }
            else if let diffResult = response.diffResult,
                    diffResult.operations.count > diffChanges.count {
                updateDiffChangesForNewOperations()
                diffChanges = getDiffChanges()
            }
        } else {
            if diffChanges.isEmpty && response.diffResult != nil {
                createDiffChanges()
                diffChanges = getDiffChanges()
            }
            else if let diffResult = response.diffResult,
                    diffResult.operations.count > diffChanges.count {
                updateDiffChangesForNewOperations()
                diffChanges = getDiffChanges()
            }
        }
        
        if let firstPending = diffChanges.first(where: { $0.status == .pending }) {
            currentOperationIndex = firstPending.operationIndex
        }
    }
    
    // MARK: - Database Operations
    
    private func getDiffChanges() -> [DiffChangeState] {
        return response.currentDiffChanges.sorted { $0.operationIndex < $1.operationIndex }
    }
    
    private func getDiffChange(operationIndex: Int) -> DiffChangeState? {
        return response.currentDiffChanges.first { $0.operationIndex == operationIndex }
    }
    
    private func createDiffChanges() {
        guard let diffResult = response.diffResult else {
            return
        }
        
        if !diffChanges.isEmpty {
            if diffChanges.count == diffResult.operations.count {
                return
            }
        }
        
        var newRevisionChanges: [DiffChangeState] = []
        
        for (index, operation) in diffResult.operations.enumerated() {
            let diffChange = DiffChangeState(
                operationIndex: index,
                operationType: operation.type,
                status: .pending,
                operationText: operation.text ?? operation.newText,
                operationStartIndex: operation.startIndex ?? operation.index,
                operationEndIndex: operation.endIndex
            )
            modelContext.insert(diffChange)
            newRevisionChanges.append(diffChange)
        }
        
        response.createNewDiffRevision(with: newRevisionChanges)
        saveContext(modelContext)
    }
    
    private func updateDiffChangesForNewOperations() {
        guard let diffResult = response.diffResult else { return }
        
        let existingCount = diffChanges.count
        let totalOperations = diffResult.operations.count
        
        guard totalOperations > existingCount else { return }
        
        var newChanges: [DiffChangeState] = []
        
        for index in existingCount..<totalOperations {
            let operation = diffResult.operations[index]
            let diffChange = DiffChangeState(
                operationIndex: index,
                operationType: operation.type,
                status: .pending,
                operationText: operation.text ?? operation.newText,
                operationStartIndex: operation.startIndex ?? operation.index,
                operationEndIndex: operation.endIndex
            )
            modelContext.insert(diffChange)
            newChanges.append(diffChange)
        }
        
        response.addDiffChangesToCurrentRevision(newChanges)
        saveContext(modelContext)
    }
    
    private func updateDiffChangeStatus(operationIndex: Int, status: DiffChangeStatus) {
        if let diffChange = getDiffChange(operationIndex: operationIndex) {
            diffChange.status = status
            diffChange.timestamp = Date()
            
            if status == .approved {
                recalculateIndicesAfterApproval(approvedOperationIndex: operationIndex)
            }
            
            saveContext(modelContext)
        }
    }
    
    private func recalculateIndicesAfterApproval(approvedOperationIndex: Int) {
        guard let diffResult = response.diffResult,
              approvedOperationIndex < diffResult.operations.count else { return }
        
        let allChanges = getDiffChanges().sorted { $0.operationIndex < $1.operationIndex }
        let approvedOperation = diffResult.operations[approvedOperationIndex]
        let offset = calculateOffsetForOperation(approvedOperation)
        
        for change in allChanges {
            if change.operationIndex > approvedOperationIndex && change.status == .pending {
                updateIndicesForChange(change, withOffset: offset)
            }
        }
    }
    
    private func calculateOffsetForOperation(_ operation: DiffTool.PlainTextDiffOperation) -> Int {
        switch operation.type {
        case "insertText":
            return operation.text?.count ?? 0
            
        case "deleteContentRange":
            if let startIndex = operation.startIndex, let endIndex = operation.endIndex {
                return -(endIndex - startIndex)
            }
            return 0
            
        case "replaceText":
            if let startIndex = operation.startIndex, 
               let endIndex = operation.endIndex,
               let newText = operation.newText {
                let deletedLength = endIndex - startIndex
                let insertedLength = newText.count
                return insertedLength - deletedLength
            }
            return 0
            
        default:
            return 0
        }
    }
    
    private func updateIndicesForChange(_ change: DiffChangeState, withOffset offset: Int) {
        if let startIndex = change.operationStartIndex {
            change.operationStartIndex = max(0, startIndex + offset)
        }
        
        if let endIndex = change.operationEndIndex {
            change.operationEndIndex = max(0, endIndex + offset)
        }
    }
    
    private func getAdjustedDiffChanges() -> [DiffChangeData] {
        let changes = getDiffChanges()
        var adjustedChanges: [DiffChangeData] = []
        var cumulativeOffset = 0
        
        for change in changes.sorted(by: { $0.operationIndex < $1.operationIndex }) {
            if change.status == .approved {
                if let operation = getOperation(for: change) {
                    let originalStartIndex: Int?
                    let originalEndIndex: Int?
                    
                    switch operation.type {
                    case "insertText":
                        originalStartIndex = operation.index
                        originalEndIndex = nil
                    case "deleteContentRange", "replaceText":
                        originalStartIndex = operation.startIndex
                        originalEndIndex = operation.endIndex
                    default:
                        originalStartIndex = change.operationStartIndex
                        originalEndIndex = change.operationEndIndex
                    }
                    
                    adjustedChanges.append(DiffChangeData(
                        operationIndex: change.operationIndex,
                        operationType: change.operationType,
                        status: change.status,
                        operationText: change.operationText,
                        operationStartIndex: originalStartIndex,
                        operationEndIndex: originalEndIndex
                    ))
                    
                    cumulativeOffset += calculateOffsetForOperation(operation)
                } else {
                    // Fallback if operation not found
                    adjustedChanges.append(DiffChangeData(
                        operationIndex: change.operationIndex,
                        operationType: change.operationType,
                        status: change.status,
                        operationText: change.operationText,
                        operationStartIndex: change.operationStartIndex,
                        operationEndIndex: change.operationEndIndex
                    ))
                }
            } else {
                let adjustedStartIndex = change.operationStartIndex.map { max(0, $0 + cumulativeOffset) }
                let adjustedEndIndex = change.operationEndIndex.map { max(0, $0 + cumulativeOffset) }
                
                adjustedChanges.append(DiffChangeData(
                    operationIndex: change.operationIndex,
                    operationType: change.operationType,
                    status: change.status,
                    operationText: change.operationText,
                    operationStartIndex: adjustedStartIndex,
                    operationEndIndex: adjustedEndIndex
                ))
            }
        }
        
        return adjustedChanges
    }
    
    private func getOperation(for change: DiffChangeState) -> DiffTool.PlainTextDiffOperation? {
        guard let diffResult = response.diffResult,
              change.operationIndex < diffResult.operations.count else {
            return nil
        }
        return diffResult.operations[change.operationIndex]
    }
    
    private func getChangeStatistics() -> (pending: Int, approved: Int, rejected: Int) {
        let changes = getDiffChanges()
        
        let pending = changes.filter { $0.status == .pending }.count
        let approved = changes.filter { $0.status == .approved }.count
        let rejected = changes.filter { $0.status == .rejected }.count
        
        return (pending: pending, approved: approved, rejected: rejected)
    }
    
    private func getNextPendingChange(after currentIndex: Int) -> DiffChangeState? {
        let changes = getDiffChanges()
            .filter { $0.status == .pending && $0.operationIndex > currentIndex }
        return changes.first
    }
    
    private func getPreviousPendingChange(before currentIndex: Int) -> DiffChangeState? {
        let changes = getDiffChanges()
            .filter { $0.status == .pending && $0.operationIndex < currentIndex }
        return changes.last
    }
    
    private func saveContext(_ context: ModelContext) {
        do {
            try context.save()
        } catch {
            print("Error saving diff changes: \(error)")
        }
    }
    
    // MARK: - Actions
    
    func createVariant() {
        response.createVariantWithContext(modelContext)
        
        resetViewModel()
    }
    
    func approveCurrentChange() {
        updateCurrentChangeStatus(.approved)
    }
    
    func rejectCurrentChange() {
        updateCurrentChangeStatus(.rejected)
    }
    
    func approveAllChanges() {
        let pendingChanges = diffChanges.filter { $0.status == .pending }
            .sorted { $0.operationIndex < $1.operationIndex }
        
        for change in pendingChanges {
            updateDiffChangeStatus(
                operationIndex: change.operationIndex,
                status: .approved
            )
        }

        refreshChanges()
        hasUnsavedChanges = true
    }
    
    func rejectAllChanges() {
        let pendingChanges = diffChanges.filter { $0.status == .pending }
        
        for change in pendingChanges {
            updateDiffChangeStatus(
                operationIndex: change.operationIndex,
                status: .rejected
            )
        }
        
        refreshChanges()
    }
    
    // MARK: - Navigation
    
    func navigateToNextAvailablePendingChange() {
        if let nextPending = getNextPendingChange(after: currentOperationIndex) {
            currentOperationIndex = nextPending.operationIndex
            return
        }
        
        let pendingChanges = diffChanges.filter { $0.status == .pending }
            .sorted { $0.operationIndex < $1.operationIndex }
        
        if let lastPending = pendingChanges.last {
            currentOperationIndex = lastPending.operationIndex
        }
    }
    
    func navigateToPreviousAvailablePendingChange() {
        if let previousPending = getPreviousPendingChange(before: currentOperationIndex) {
            currentOperationIndex = previousPending.operationIndex
            return
        }
        
        let pendingChanges = diffChanges.filter { $0.status == .pending }
            .sorted { $0.operationIndex < $1.operationIndex }
        
        if let firstPending = pendingChanges.first {
            currentOperationIndex = firstPending.operationIndex
        }
    }
    
    // MARK: - Text Generation
    
    func clearInsertionError() {
        insertionError = nil
    }
    
    // MARK: - Insertion
    
    func insert() {
        guard let diffArguments = diffArguments else {
            insertionError = "No arguments available"
            return
        }
        
        if let documentUrl = diffArguments.document_url {
            Task {
                await insertToDocument(documentUrl: documentUrl)
            }
        } else {
            let appName = diffArguments.app_name
            let runningApps = NSWorkspace.shared.runningApplications
            
            guard let runningApp = runningApps.first(where: { app in
                app.localizedName?.localizedCaseInsensitiveContains(appName) == true
            }) else {
                insertionError = "Application '\(appName)' is not running. Please open the application and try again."
                return
            }
            
            guard let diffPreview = response.diffPreview else {
                insertionError = "No text available. Please approve some changes before inserting."
                return
            }
            
            runningApp.activate()
            
            let source = CGEventSource(stateID: .hidSystemState)
            let pasteDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
            let pasteUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
            
            pasteDown?.flags = .maskCommand
            pasteUp?.flags = .maskCommand
            
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(diffPreview, forType: .string)
            
            pasteDown?.post(tap: .cghidEventTap)
            pasteUp?.post(tap: .cghidEventTap)
        }
    }
    
    @MainActor
    private func insertToDocument(documentUrl: String) async {
        isInserting = true
        insertionError = nil
        
        do {
            try await applyApprovedChangesToDocument(documentUrl: documentUrl)
        } catch {
            insertionError = error.localizedDescription
        }
        
        hasUnsavedChanges = false
        isInserting = false
    }
    
    func applyApprovedChangesToDocument(documentUrl: String) async throws {
        let adjustedChanges = getAdjustedDiffChanges()
        let approvedChanges = adjustedChanges.filter { $0.status == .approved }
        
		guard !approvedChanges.isEmpty else {
            log.error("no approved changes")
            return
        }
        
        try await GoogleDocumentManager.applyDiffChangesToDocument(
            documentUrl: documentUrl,
            diffChanges: approvedChanges
        )
    }
    
    // MARK: - Preview Mode
    
    func startPreviewingAllApproved() {
        isPreviewingAllApproved = true
    }
    
    func stopPreviewingAllApproved() {
        isPreviewingAllApproved = false
    }
    
    func getEffectiveDiffChanges() -> [DiffChangeData] {
        let adjustedChanges = getAdjustedDiffChanges()
        
        if isPreviewingAllApproved {
            return adjustedChanges.map { change in
                DiffChangeData(
                    operationIndex: change.operationIndex,
                    operationType: change.operationType,
                    status: change.status == .pending ? .approved : change.status,
                    operationText: change.operationText,
                    operationStartIndex: change.operationStartIndex,
                    operationEndIndex: change.operationEndIndex
                )
            }
        } else {
            return adjustedChanges
        }
    }
    
    // MARK: - Private

	private func updateCurrentChangeStatus(_ status: DiffChangeStatus) {
        updateDiffChangeStatus(
            operationIndex: currentOperationIndex,
            status: status
        )
        refreshChanges()
        
        if status == .approved {
            hasUnsavedChanges = true
        }
        
        navigateToNextAvailablePendingChange()
    }
    
    private func refreshChanges() {
        diffChanges = getDiffChanges()
    }

	private func resetViewModel() {
        loadOrCreateDiffChanges()
        
        hasUnsavedChanges = false
        isPreviewingAllApproved = false
        isInserting = false
        insertionError = nil
    }
} 
