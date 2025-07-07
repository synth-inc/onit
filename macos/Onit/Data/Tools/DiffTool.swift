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

struct DiffTool {
    static let availableTools: [String: Tool] = [
        "plain_text": Tool(
            name: "diff_plain_text",
            description: "Generate structured text modifications by comparing original plain text content with your improved version.",
            parameters: ToolParameters(
                properties: [
                    "source_name": ToolProperty(
                        type: "string",
                        description: "Name of the source from which text content was extracted",
                        items: nil
                    ),
                    "source_title": ToolProperty(
                        type: "string",
                        description: "Title of the source document or window",
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
                required: ["source_name", "source_title", "original_content", "improved_content"]
            )
        )
    ]

    @MainActor
    static var selectedTools: [String] = ["plain_text"]

    @MainActor
    static var activeTools: [Tool] {
        return
            availableTools
            .filter { selectedTools.contains($0.key) }
            .map { availableTools[$0.key]! }
    }

    static func executeToolCall(toolName: String, arguments: String) async -> Result<
        ToolCallResult, ToolCallError
    > {
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
        let source_name: String
        let source_title: String
        let original_content: String
        let improved_content: String
    }

    struct PlainTextDiffOperation: Codable {
        let type: String // "insertText", "deleteContentRange", "replaceText"
        let index: Int? // For insertText operations
        let startIndex: Int? // For delete/replace operations
        let endIndex: Int? // For delete/replace operations
        let text: String? // For insertText operations
        let newText: String? // For replaceText operations
    }

    struct PlainTextDiffResult: Codable {
        let operations: [PlainTextDiffOperation]
    }

    static func generatePlainTextDiff(toolName: String, arguments: String) async -> Result<
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

    private static func generateDiffOperations(original: String, improved: String) -> [PlainTextDiffOperation] {
        let diffs = diff(text1: original, text2: improved)
        var operations: [PlainTextDiffOperation] = []
        var currentIndex = 0
        
        for diffOp in diffs {
            switch diffOp {
            case .equal(let text):
                currentIndex += text.count
            case .delete(let text):
                operations.append(PlainTextDiffOperation(
                    type: "deleteContentRange",
                    index: nil,
                    startIndex: currentIndex,
                    endIndex: currentIndex + text.count,
                    text: nil,
                    newText: nil
                ))
                currentIndex += text.count
                
            case .insert(let text):
                operations.append(PlainTextDiffOperation(
                    type: "insertText",
                    index: currentIndex,
                    startIndex: nil,
                    endIndex: nil,
                    text: text,
                    newText: nil
                ))
            }
        }
        
        return operations
	}
}

public func diff(text1: String, text2: String) -> [DiffOperation] {
    if text1 == text2 {
        return text1.isEmpty ? [] : [.equal(text1)]
    }
    
    let (commonPrefix, trimmedText1, trimmedText2) = extractCommonPrefix(text1: text1, text2: text2)
    let (commonSuffix, finalText1, finalText2) = extractCommonSuffix(text1: trimmedText1, text2: trimmedText2)
    let diffs = computeDiff(text1: finalText1, text2: finalText2)
    var result = diffs
    
    if !commonPrefix.isEmpty {
        result.insert(.equal(commonPrefix), at: 0)
    }
    if !commonSuffix.isEmpty {
        result.append(.equal(commonSuffix))
    }
    
    return result
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

private func computeDiff(text1: String, text2: String) -> [DiffOperation] {
    if text1.isEmpty {
        return text2.isEmpty ? [] : [.insert(text2)]
    }
    
    if text2.isEmpty {
        return [.delete(text1)]
    }
    
    return myersDiff(text1: text1, text2: text2)
}

private func myersDiff(text1: String, text2: String) -> [DiffOperation] {
    let chars1 = Array(text1)
    let chars2 = Array(text2)
    let n = chars1.count
    let m = chars2.count
    
    if n == 0 {
        return [.insert(text2)]
    }
    if m == 0 {
        return [.delete(text1)]
    }
    
    let max = n + m
    var v = Array(repeating: 0, count: 2 * max + 1)
    var trace: [[Int]] = []
    
    for d in 0...max {
        trace.append(v)
        
        for k in stride(from: -d, through: d, by: 2) {
            let kIndex = k + max
            
            var x: Int
            if k == -d || (k != d && v[kIndex - 1] < v[kIndex + 1]) {
                x = v[kIndex + 1]
            } else {
                x = v[kIndex - 1] + 1
            }
            
            var y = x - k
            
            while x < n && y < m && chars1[x] == chars2[y] {
                v[kIndex] = x + 1
                if x + 1 < n && y + 1 < m {
                    x += 1
                    y += 1
                } else {
                    break
                }
            }
            
            v[kIndex] = x
            
            if x >= n && y >= m {
                return backtrack(chars1: chars1, chars2: chars2, trace: trace, d: d)
            }
        }
    }
    
    // Fallback to simple diff
    return [.delete(text1), .insert(text2)]
}

private func backtrack(chars1: [Character], chars2: [Character], trace: [[Int]], d: Int) -> [DiffOperation] {
    var result: [DiffOperation] = []
    var x = chars1.count
    var y = chars2.count
    
    for step in stride(from: d, through: 0, by: -1) {
        let v = trace[step]
        let max = chars1.count + chars2.count
        let k = x - y
        let kIndex = k + max
        
        let prevK: Int
        if k == -step || (k != step && v[kIndex - 1] < v[kIndex + 1]) {
            prevK = k + 1
        } else {
            prevK = k - 1
        }
        
        let prevX = v[prevK + max]
        let prevY = prevX - prevK
        
        while x > prevX && y > prevY {
            result.insert(.equal(String(chars1[x - 1])), at: 0)
            x -= 1
            y -= 1
        }
        
        if step > 0 {
            if x > prevX {
                result.insert(.delete(String(chars1[x - 1])), at: 0)
                x -= 1
            } else {
                result.insert(.insert(String(chars2[y - 1])), at: 0)
                y -= 1
            }
        }
    }
    
    return result
}
