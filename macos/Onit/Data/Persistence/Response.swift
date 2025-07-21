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
    
    @Relationship(deleteRule: .cascade) 
	var diffRevisions: [DiffRevision] = []
	
    var currentDiffRevisionIndex: Int = 0

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
    var currentDiffChanges: [DiffChangeState] {
        guard currentDiffRevisionIndex < diffRevisions.count else { return [] }
        return diffRevisions[currentDiffRevisionIndex].diffChanges
    }
    
    var currentDiffRevision: DiffRevision? {
        guard currentDiffRevisionIndex < diffRevisions.count else { return nil }
        return diffRevisions[currentDiffRevisionIndex]
    }
    
    var totalDiffRevisions: Int {
        return diffRevisions.count
    }
    
    func createNewDiffRevision(with diffChanges: [DiffChangeState]) {
        let newRevision = DiffRevision(index: diffRevisions.count)
        newRevision.diffChanges = diffChanges
        diffRevisions.append(newRevision)
        currentDiffRevisionIndex = diffRevisions.count - 1
    }
    
    /// Adds a diff change to the current revision, creating one if none exists
    func addDiffChangeToCurrentRevision(_ diffChange: DiffChangeState) {
        if diffRevisions.isEmpty {
            let newRevision = DiffRevision(index: 0)
            diffRevisions.append(newRevision)
            currentDiffRevisionIndex = 0
        }
        
        if let currentRevision = currentDiffRevision {
            currentRevision.diffChanges.append(diffChange)
        }
    }
    
    func setCurrentRevision(index: Int) {
        guard index >= 0 && index < diffRevisions.count else { return }
        currentDiffRevisionIndex = index
    }
}
