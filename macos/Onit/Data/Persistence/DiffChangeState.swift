//
//  DiffChangeState.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import Foundation
import SwiftData

@Model
class DiffChangeState {
    var responseId: String
    var operationIndex: Int
    var operationType: String // "insertText", "deleteContentRange", "replaceText"
    var status: DiffChangeStatus
    var timestamp: Date
    var operationText: String?
    var operationStartIndex: Int?
    var operationEndIndex: Int?
    
    init(responseId: String, operationIndex: Int, operationType: String, status: DiffChangeStatus = .pending, operationText: String? = nil, operationStartIndex: Int? = nil, operationEndIndex: Int? = nil) {
        self.responseId = responseId
        self.operationIndex = operationIndex
        self.operationType = operationType
        self.status = status
        self.timestamp = Date()
        self.operationText = operationText
        self.operationStartIndex = operationStartIndex
        self.operationEndIndex = operationEndIndex
    }
}

enum DiffChangeStatus: String, Codable, CaseIterable {
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