//
//  Response.swift
//  Onit
//
//  Created by Benjamin Sage on 11/2/24.
//

import Foundation
import SwiftData

@Model
class Response {
    var text: String
    var instruction: String?
    var timestamp: Date
    var type: ResponseType
    var model: String?

    // Tool call properties
    var toolCallName: String?
    var toolCallArguments: String?
    var toolCallResult: String?
    var toolCallSuccess: Bool?
    
    // Diff view
    var currentDiffRevisionIndex: Int = 0
    var shouldDisplayDiffToolView = true
    
    @Relationship(deleteRule: .cascade, inverse: \DiffRevision.response)
	var diffRevisions: [DiffRevision] = []

    init(text: String, instruction: String?, type: ResponseType, model: String, time: Date = .now) {
        self.text = text
        self.instruction = instruction
        self.timestamp = time
        self.type = type
        self.model = model
    }
    
    static var partial: Response {
        .init(text: "", instruction: "", type: .partial, model: "")
    }
    
    var isPartial: Bool {
        type == .partial
    }

    var hasToolCall: Bool {
        toolCallName?.isEmpty == false
    }
}

enum ResponseType: String, Codable {
    case partial
    case success
    case error
}

// MARK: - Diff tool

extension Response {
    var isDiffResponse: Bool {
        return toolCallName?.hasPrefix("diff_") == true
    }
    
    var diffArguments: DiffTool.PlainTextDiffArguments? {
        guard let argumentsData = toolCallArguments?.data(using: .utf8) else { return nil }
        
        return try? JSONDecoder().decode(DiffTool.PlainTextDiffArguments.self, from: argumentsData)
    }
    
    var diffResult: DiffTool.PlainTextDiffResult? {
        guard let resultData = toolCallResult?.data(using: .utf8) else { return nil }
        
        return try? JSONDecoder().decode(DiffTool.PlainTextDiffResult.self, from: resultData)
    }
}
    
// MARK: - Diff Revisions
extension Response {
    var sortedDiffRevisions: [DiffRevision] {
        return diffRevisions.sorted { $0.index < $1.index }
    }
    
    var currentDiffChanges: [DiffChangeState] {
        guard let currentRevision = currentDiffRevision else { return [] }
        return currentRevision.diffChanges
    }
    
    var currentDiffRevision: DiffRevision? {
        return diffRevisions.first { $0.index == currentDiffRevisionIndex }
    }
    
    var totalDiffRevisions: Int {
        return diffRevisions.count
    }
    
    private var nextRevisionIndex: Int {
        return (diffRevisions.map { $0.index }.max() ?? -1) + 1
    }
    
    func createNewDiffRevision(with diffChanges: [DiffChangeState]) {
        let newIndex = nextRevisionIndex
        let newRevision = DiffRevision(index: newIndex)
        newRevision.diffChanges = diffChanges
        newRevision.response = self
        diffRevisions.append(newRevision)
        currentDiffRevisionIndex = newIndex
    }
    
    func addDiffChangeToCurrentRevision(_ diffChange: DiffChangeState) {
        if diffRevisions.isEmpty {
            let newRevision = DiffRevision(index: 0)
            newRevision.response = self
            diffRevisions.append(newRevision)
            currentDiffRevisionIndex = 0
        }
        
        if let currentRevision = currentDiffRevision {
            currentRevision.diffChanges.append(diffChange)
        }
    }
    
    func setCurrentRevision(index: Int) {
        guard diffRevisions.contains(where: { $0.index == index }) else { return }
        currentDiffRevisionIndex = index
    }
    
    func addDiffChangesToCurrentRevision(_ diffChanges: [DiffChangeState]) {
        if diffRevisions.isEmpty {
            let newRevision = DiffRevision(index: 0)
            newRevision.response = self
            diffRevisions.append(newRevision)
            currentDiffRevisionIndex = 0
        }
        
        if let currentRevision = currentDiffRevision {
            currentRevision.diffChanges.append(contentsOf: diffChanges)
        }
    }
    
    func clearCurrentDiffRevision() {
        if let currentRevision = currentDiffRevision {
            currentRevision.diffChanges.removeAll()
        }
    }
    
    func createNewRevisionFromOriginal() -> [DiffChangeState] {
        guard let diffResult = diffResult else { return [] }
        
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
            newRevisionChanges.append(diffChange)
        }
        
        let newIndex = nextRevisionIndex
        let newRevision = DiffRevision(index: newIndex)
        newRevision.diffChanges = newRevisionChanges
        newRevision.response = self
        diffRevisions.append(newRevision)
        currentDiffRevisionIndex = newIndex
        
        return newRevisionChanges
    }
    
    func createVariantWithContext(_ modelContext: ModelContext) {
        let newChanges = createNewRevisionFromOriginal()
        
        if let newRevision = diffRevisions.last {
            modelContext.insert(newRevision)
        }
        
        for change in newChanges {
            modelContext.insert(change)
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving variant: \(error)")
        }
    }
}
