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
    @Relationship(deleteRule: .cascade, inverse: \DiffChangeState.revision)
    var diffChanges: [DiffChangeState] = []
    
    var response: Response?
    
    init(index: Int) {
        self.index = index
        self.createdAt = Date()
    }
}

@Model
class DiffChangeState {
    var operationIndex: Int
    var operationType: DiffOperationType
    var status: DiffChangeStatus
    var timestamp: Date
    var operationText: String?
    var operationStartIndex: Int?
    var operationEndIndex: Int?
    
    var revision: DiffRevision?
    
    init(operationIndex: Int, operationType: DiffOperationType, status: DiffChangeStatus = .pending, operationText: String? = nil, operationStartIndex: Int? = nil, operationEndIndex: Int? = nil) {
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
    let operationType: DiffOperationType
    let status: DiffChangeStatus
    let operationText: String?
    let operationStartIndex: Int?
    let operationEndIndex: Int?
    
    init(operationIndex: Int, operationType: DiffOperationType, status: DiffChangeStatus, operationText: String? = nil, operationStartIndex: Int? = nil, operationEndIndex: Int? = nil) {
        self.operationIndex = operationIndex
        self.operationType = operationType
        self.status = status
        self.operationText = operationText
        self.operationStartIndex = operationStartIndex
        self.operationEndIndex = operationEndIndex
    }
}

enum DiffOperationType: String, Codable, CaseIterable, Sendable {
    case insertText = "insertText"
    case deleteContentRange = "deleteContentRange"
    case replaceText = "replaceText"
    
    var priority: Int {
        switch self {
        case .deleteContentRange: return 0  // Highest priority
        case .replaceText: return 1         // Medium priority  
        case .insertText: return 2          // Lowest priority
        }
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
