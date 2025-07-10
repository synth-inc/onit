//
//  DiffChangeState.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import Foundation
import SwiftData

@Model
class DiffRevision {
    var index: Int
    var createdAt: Date
    var diffChanges: [DiffChangeState] = []
    
    init(index: Int) {
        self.index = index
        self.createdAt = Date()
    }
}

@Model
class DiffChangeState {
    var operationIndex: Int
    var operationType: String // "insertText", "deleteContentRange", "replaceText"
    var status: DiffChangeStatus
    var timestamp: Date
    var operationText: String?
    var operationStartIndex: Int?
    var operationEndIndex: Int?
    
    init(operationIndex: Int, operationType: String, status: DiffChangeStatus = .pending, operationText: String? = nil, operationStartIndex: Int? = nil, operationEndIndex: Int? = nil) {
        self.operationIndex = operationIndex
        self.operationType = operationType
        self.status = status
        self.timestamp = Date()
        self.operationText = operationText
        self.operationStartIndex = operationStartIndex
        self.operationEndIndex = operationEndIndex
    }
}

// MARK: - Sendable Data Transfer Object

struct DiffChangeData: Sendable {
    let operationIndex: Int
    let operationType: String
    let status: DiffChangeStatus
    let operationText: String?
    let operationStartIndex: Int?
    let operationEndIndex: Int?
    
    init(operationIndex: Int, operationType: String, status: DiffChangeStatus, operationText: String? = nil, operationStartIndex: Int? = nil, operationEndIndex: Int? = nil) {
        self.operationIndex = operationIndex
        self.operationType = operationType
        self.status = status
        self.operationText = operationText
        self.operationStartIndex = operationStartIndex
        self.operationEndIndex = operationEndIndex
    }
}

enum DiffChangeStatus: String, Codable, CaseIterable, Sendable {
    case pending
    case approved
    case rejected
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        }
    }
} 