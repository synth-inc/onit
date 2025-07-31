//
//  DiffTool.swift
//  Onit
//
//  Created by Kévin Naudin on 07/04/25.
//

import Foundation

public enum DiffOperation {
    case equal(String)
    case delete(String)
    case insert(String)
}

class DiffTool: ToolProtocol {
    
    private let availableTools: [String: Tool] = [
        "plain_text": Tool(
            name: "diff_plain_text",
            description: "Generate structured text modifications for any text improvements including corrections, edits, proofreading, grammar fixes, spelling fixes, or content enhancements. Use this tool whenever you need to apply changes to existing text content.",
            parameters: ToolParameters(
                properties: [
                    "app_name": ToolProperty(
                        type: "string",
                        description: "Name of the app from which text content was extracted",
                        items: nil
                    ),
                    "document_url": ToolProperty(
                        type: "string",
                        description: "Optional URL of the document",
                        items: nil
                    ),
                    "original_content": ToolProperty(
                        type: "string",
                        description: "Original plain text content before improvements",
                        items: nil
                    ),
                    "improved_content": ToolProperty(
                        type: "string",
                        description: "Your corrected/improved version of the text content",
                        items: nil
                    )
                ],
                required: ["app_name", "original_content", "improved_content"]
            )
        )
    ]

    private var selectedTools: [String] = ["plain_text"]

    var activeTools: [Tool] {
        return availableTools
            .compactMap { selectedTools.contains($0.key) ? $0.value : nil }
    }
    
    func canExecute(partialArguments: String) -> Bool {
        guard let data = partialArguments.data(using: .utf8) else {
            return false
        }
        
        do {
            let decoded = try JSONDecoder().decode(PlainTextDiffArguments.self, from: data)
            
            let originalHasContent = decoded.original_content.count >= 10
            let improvedHasContent = decoded.improved_content.count >= 10
            
            return originalHasContent && improvedHasContent
        } catch {
            return false
        }
    }

    func execute(toolName: String, arguments: String) async -> Result<ToolCallResult, ToolCallError> {
        switch toolName {
        case "plain_text":
            return await generatePlainTextDiff(toolName: toolName, arguments: arguments)
        default:
            return .failure(
                ToolCallError(
                    toolName: toolName, message: "Unsupported tool name"))
        }
    }

    struct PlainTextDiffArguments: Codable {
        let app_name: String
        let original_content: String
        let improved_content: String
        let document_url: String?
    }

    struct PlainTextDiffOperation: Codable {
        let type: DiffOperationType
        let index: Int? // For insertText operations
        let startIndex: Int? // For delete/replace operations
        let endIndex: Int? // For delete/replace operations
        let text: String? // For insertText operations
        let newText: String? // For replaceText operations
    }

    struct PlainTextDiffResult: Codable {
        let operations: [PlainTextDiffOperation]
    }

    func generatePlainTextDiff(toolName: String, arguments: String) async -> Result<
        ToolCallResult, ToolCallError
    > {
        do {
            guard let data = arguments.data(using: .utf8) else {
                return .failure(
                    ToolCallError(toolName: toolName, message: "Failed to parse arguments")
                )
            }

            let args = try JSONDecoder().decode(PlainTextDiffArguments.self, from: data)

            let operations = generateDiffOperations(
                original: args.original_content,
                improved: args.improved_content
            )

            let result = PlainTextDiffResult(operations: operations)

            let encoder = JSONEncoder()
            let resultData = try encoder.encode(result)
            let resultString = String(data: resultData, encoding: .utf8) ?? ""

            return .success(ToolCallResult(toolName: toolName, result: resultString))
        } catch {
            return .failure(
                ToolCallError(
                    toolName: toolName,
                    message: "Error generating plain text diff: \(error.localizedDescription)"
                )
            )
        }
    }

    private func generateDiffOperations(original: String, improved: String) -> [PlainTextDiffOperation] {
        let diffs = optimizedDiff(text1: original, text2: improved)
        var operations: [PlainTextDiffOperation] = []
        var currentIndex = 0
        
        var rawOperations: [(type: String, index: Int, text: String?)] = []
        
        for (index, diffOp) in diffs.enumerated() {
            switch diffOp {
            case .equal(let text):
                log.debug("  \(index + 1). EQUAL(\(text.count) chars) at index \(currentIndex): '\(text.prefix(20))...'")
                currentIndex += text.count
                
            case .delete(let text):
                log.debug("  \(index + 1). DELETE(\(text.count) chars) at index \(currentIndex): '\(text)'")
                rawOperations.append((type: "delete", index: currentIndex, text: text))
                currentIndex += text.count
                
            case .insert(let text):
                log.debug("  \(index + 1). INSERT(\(text.count) chars) at index \(currentIndex): '\(text)'")
                rawOperations.append((type: "insert", index: currentIndex, text: text))
            }
        }
        
        var i = 0
		
        while i < rawOperations.count {
            let current = rawOperations[i]
            
            if i + 1 < rawOperations.count {
                let next = rawOperations[i + 1]
                var deleteOp: (type: String, index: Int, text: String?)? = nil
                var insertOp: (type: String, index: Int, text: String?)? = nil
                
                if current.type == "delete" && next.type == "insert" {
                    let deleteEnd = current.index + (current.text?.count ?? 0)

                    if next.index >= current.index && next.index <= deleteEnd {
                        deleteOp = current
                        insertOp = next
                    }
                }
                else if current.type == "insert" && next.type == "delete" {
                    let deleteEnd = next.index + (next.text?.count ?? 0)

                    if current.index >= next.index && current.index <= deleteEnd {
                        insertOp = current
                        deleteOp = next
                    }
                }
                
                if let deleteOp = deleteOp, let insertOp = insertOp {
                    operations.append(PlainTextDiffOperation(
                        type: .replaceText,
                        index: nil,
                        startIndex: deleteOp.index,
                        endIndex: deleteOp.index + (deleteOp.text?.count ?? 0),
                        text: nil,
                        newText: insertOp.text
                    ))
                    i += 2
                    continue
                }
            }
            
            if current.type == "insert" {
                var insertSequence = [current]
                var j = i + 1
                
                while j < rawOperations.count && rawOperations[j].type == "insert" {
                    let nextInsert = rawOperations[j]
                    let lastInsert = insertSequence.last!
                    let lastInsertEnd = lastInsert.index + (lastInsert.text?.count ?? 0)
                    
                    if nextInsert.index <= lastInsertEnd + 5 {
                        insertSequence.append(nextInsert)
                        j += 1
                    } else {
                        break
                    }
                }
                
                if insertSequence.count >= 3 {
                    let firstInsert = insertSequence.first!
                    let lastInsert = insertSequence.last!
                    let span = lastInsert.index - firstInsert.index
                    
                    if span <= 10 {
                        let replacementText = reconstructReplacementText(
                            originalText: original,
                            insertSequence: insertSequence,
                            startIndex: firstInsert.index,
                            endIndex: lastInsert.index
                        )
                        
                        operations.append(PlainTextDiffOperation(
                            type: .replaceText,
                            index: nil,
                            startIndex: firstInsert.index,
                            endIndex: lastInsert.index,
                            text: nil,
                            newText: replacementText
                        ))
                    } else {
                        for insert in insertSequence {
                            operations.append(PlainTextDiffOperation(
                                type: .insertText,
                                index: insert.index,
                                startIndex: nil,
                                endIndex: nil,
                                text: insert.text,
                                newText: nil
                            ))
                        }
                    }
                } else {
                    for insert in insertSequence {
                        operations.append(PlainTextDiffOperation(
                            type: .insertText,
                            index: insert.index,
                            startIndex: nil,
                            endIndex: nil,
                            text: insert.text,
                            newText: nil
                        ))
                    }
                }
                
                i = j
                continue
            }
            
            switch current.type {
            case "delete":
                operations.append(PlainTextDiffOperation(
                    type: .deleteContentRange,
                    index: nil,
                    startIndex: current.index,
                    endIndex: current.index + (current.text?.count ?? 0),
                    text: nil,
                    newText: nil
                ))
                
            case "insert":
                operations.append(PlainTextDiffOperation(
                    type: .insertText,
                    index: current.index,
                    startIndex: nil,
                    endIndex: nil,
                    text: current.text,
                    newText: nil
                ))
                
            default:
                break
            }
            
            i += 1
        }
        
        return operations
	}
    
    private func reconstructReplacementText(
        originalText: String,
        insertSequence: [(type: String, index: Int, text: String?)],
        startIndex: Int,
        endIndex: Int
    ) -> String {
        var result = ""
        var currentPos = startIndex
        
        for insert in insertSequence {
            if insert.index > currentPos {
                let textStart = originalText.index(originalText.startIndex, offsetBy: currentPos)
                let textEnd = originalText.index(originalText.startIndex, offsetBy: min(insert.index, originalText.count))
                result += String(originalText[textStart..<textEnd])
            }
            
            if let insertText = insert.text {
                result += insertText
            }
            
            currentPos = insert.index
        }
        
        if currentPos < endIndex && currentPos < originalText.count {
            let textStart = originalText.index(originalText.startIndex, offsetBy: currentPos)
            let textEnd = originalText.index(originalText.startIndex, offsetBy: min(endIndex, originalText.count))
            result += String(originalText[textStart..<textEnd])
        }
        
        return result
    }
    
    private func optimizedDiff(text1: String, text2: String) -> [DiffOperation] {
        if text1 == text2 {
            return text1.isEmpty ? [] : [.equal(text1)]
        }
        
        let (commonPrefix, trimmedText1, trimmedText2) = extractCommonPrefix(text1: text1, text2: text2)
        let (commonSuffix, finalText1, finalText2) = extractCommonSuffix(text1: trimmedText1, text2: trimmedText2)
        
        if finalText1.isEmpty && finalText2.isEmpty {
            var result: [DiffOperation] = []
            if !commonPrefix.isEmpty {
                result.append(.equal(commonPrefix))
            }
            if !commonSuffix.isEmpty {
                result.append(.equal(commonSuffix))
            }
            return result
        }
        
        if finalText1.isEmpty {
            var result: [DiffOperation] = []
            if !commonPrefix.isEmpty {
                result.append(.equal(commonPrefix))
            }
            result.append(.insert(finalText2))
            if !commonSuffix.isEmpty {
                result.append(.equal(commonSuffix))
            }
            return result
        }
        
        if finalText2.isEmpty {
            var result: [DiffOperation] = []
            if !commonPrefix.isEmpty {
                result.append(.equal(commonPrefix))
            }
            result.append(.delete(finalText1))
            if !commonSuffix.isEmpty {
                result.append(.equal(commonSuffix))
            }
            return result
        }
        
        let diffs = computeOptimalDiff(text1: finalText1, text2: finalText2)
        
        var result = diffs
        if !commonPrefix.isEmpty {
            result.insert(.equal(commonPrefix), at: 0)
        }
        if !commonSuffix.isEmpty {
            result.append(.equal(commonSuffix))
        }
        
        return result
    }

    private func computeOptimalDiff(text1: String, text2: String) -> [DiffOperation] {
        let chars1 = Array(text1)
        let chars2 = Array(text2)
        let n = chars1.count
        let m = chars2.count
        
        var dp = Array(repeating: Array(repeating: 0, count: m + 1), count: n + 1)
        
        for i in 1...n {
            for j in 1...m {
                if chars1[i-1] == chars2[j-1] {
                    dp[i][j] = dp[i-1][j-1] + 1
                } else {
                    dp[i][j] = max(dp[i-1][j], dp[i][j-1])
                }
            }
        }
        
        var result: [DiffOperation] = []
        var i = n
        var j = m
        
        while i > 0 || j > 0 {
            if i > 0 && j > 0 && chars1[i-1] == chars2[j-1] {
                result.insert(.equal(String(chars1[i-1])), at: 0)
                i -= 1
                j -= 1
            } else if i > 0 && (j == 0 || dp[i-1][j] >= dp[i][j-1]) {
                result.insert(.delete(String(chars1[i-1])), at: 0)
                i -= 1
            } else if j > 0 {
                result.insert(.insert(String(chars2[j-1])), at: 0)
                j -= 1
            }
        }
        
        return mergeConsecutiveOperations(result)
    }
    
    private func mergeConsecutiveOperations(_ operations: [DiffOperation]) -> [DiffOperation] {
        guard !operations.isEmpty else { return [] }
        
        var result: [DiffOperation] = []
        var currentOp = operations[0]
        
        for i in 1..<operations.count {
            let nextOp = operations[i]
            
            switch (currentOp, nextOp) {
            case (.equal(let text1), .equal(let text2)):
                currentOp = .equal(text1 + text2)
            case (.delete(let text1), .delete(let text2)):
                currentOp = .delete(text1 + text2)
            case (.insert(let text1), .insert(let text2)):
                currentOp = .insert(text1 + text2)
            default:
                result.append(currentOp)
                currentOp = nextOp
            }
        }
        
        result.append(currentOp)
        return result
    }
}

private func extractCommonPrefix(text1: String, text2: String) -> (String, String, String) {
    let chars1 = Array(text1)
    let chars2 = Array(text2)
    let minLength = min(chars1.count, chars2.count)
    
    var prefixLength = 0
    for i in 0..<minLength {
        if chars1[i] != chars2[i] {
            break
        }
        prefixLength += 1
    }
    
    if prefixLength == 0 {
        return ("", text1, text2)
    }
    
    let prefix = String(chars1[0..<prefixLength])
    let remaining1 = String(chars1[prefixLength...])
    let remaining2 = String(chars2[prefixLength...])
    
    return (prefix, remaining1, remaining2)
}

private func extractCommonSuffix(text1: String, text2: String) -> (String, String, String) {
    let chars1 = Array(text1)
    let chars2 = Array(text2)
    let minLength = min(chars1.count, chars2.count)
    
    if minLength == 0 {
        return ("", text1, text2)
    }
    
    var suffixLength = 0
    for i in 1...minLength {
        if chars1[chars1.count - i] != chars2[chars2.count - i] {
            break
        }
        suffixLength += 1
    }
    
    if suffixLength == 0 {
        return ("", text1, text2)
    }
    
    let suffix = String(chars1[(chars1.count - suffixLength)...])
    let remaining1 = String(chars1[0..<(chars1.count - suffixLength)])
    let remaining2 = String(chars2[0..<(chars2.count - suffixLength)])
    
    return (suffix, remaining1, remaining2)
}

