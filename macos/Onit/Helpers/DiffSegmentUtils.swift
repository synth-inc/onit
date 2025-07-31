//
//  DiffSegmentUtils.swift
//  Onit
//
//  Created by Kévin Naudin on 29/07/2025.
//

import Foundation

struct DiffSegmentUtils {
    
    static func shouldSegmentBeVisible(segment: DiffSegment, status: DiffChangeStatus?) -> Bool {
        return segment.type == .unchanged ||
            (segment.type == .added && status != .rejected) ||
            (segment.type == .removed && status != .approved)
    }
    
    static func generateDiffSegments(
        originalText: String, 
        operations: [DiffTool.PlainTextDiffOperation]
    ) -> [DiffSegment] {
        let sortedOperations = operations.sorted { (op1, op2) in
            let pos1 = op1.startIndex ?? op1.index ?? 0
            let pos2 = op2.startIndex ?? op2.index ?? 0
            
            if pos1 == pos2 {
                return op1.type.priority < op2.type.priority
            }
            
            return pos1 < pos2
        }
        
        var segments: [DiffSegment] = []
        var currentPosition = 0
        
        for (opIndex, operation) in sortedOperations.enumerated() {
            let operationStart: Int
            
            switch operation.type {
            case .insertText:
                operationStart = operation.index ?? 0
            case .deleteContentRange, .replaceText:
                operationStart = operation.startIndex ?? 0
            }
            
            if currentPosition < operationStart {
                let unchangedText = String(originalText[originalText.index(originalText.startIndex, offsetBy: currentPosition)..<originalText.index(originalText.startIndex, offsetBy: operationStart)])
                if !unchangedText.isEmpty {
                    segments.append(DiffSegment(
                        content: unchangedText,
                        type: .unchanged,
                        operationIndex: nil
                    ))
                }
            }
            
            switch operation.type {
            case .insertText:
                if let text = operation.text {
                    segments.append(DiffSegment(
                        content: text,
                        type: .added,
                        operationIndex: opIndex
                    ))
                }
                currentPosition = max(currentPosition, operationStart)
                
            case .deleteContentRange:
                if let endIndex = operation.endIndex {
                    let deletedText = String(originalText[originalText.index(originalText.startIndex, offsetBy: operationStart)..<originalText.index(originalText.startIndex, offsetBy: endIndex)])
                    segments.append(DiffSegment(
                        content: deletedText,
                        type: .removed,
                        operationIndex: opIndex
                    ))
                    currentPosition = endIndex
                }
                
            case .replaceText:
                if let endIndex = operation.endIndex,
                   let newText = operation.newText {
                    let deletedText = String(originalText[originalText.index(originalText.startIndex, offsetBy: operationStart)..<originalText.index(originalText.startIndex, offsetBy: endIndex)])
                    segments.append(DiffSegment(
                        content: deletedText,
                        type: .removed,
                        operationIndex: opIndex
                    ))
                    segments.append(DiffSegment(
                        content: newText,
                        type: .added,
                        operationIndex: opIndex
                    ))
                    currentPosition = endIndex
                }
            }
        }
        
        if currentPosition < originalText.count {
            let remainingText = String(originalText[originalText.index(originalText.startIndex, offsetBy: currentPosition)...])
            if !remainingText.isEmpty {
                segments.append(DiffSegment(
                    content: remainingText,
                    type: .unchanged,
                    operationIndex: nil
                ))
            }
        }
        
        return segments
    }
    
    static func generateTextFromSegments(
        segments: [DiffSegment],
        effectiveChanges: [DiffChangeData]
    ) -> String {
        var result = ""
        for segment in segments {
            let segmentStatus: DiffChangeStatus? = {
                guard let opIndex = segment.operationIndex else { return nil }
                return effectiveChanges.first { $0.operationIndex == opIndex }?.status
            }()
            
            let isVisible = shouldSegmentBeVisible(segment: segment, status: segmentStatus)
            if isVisible {
                result += segment.content
            }
        }
        return result
    }
} 