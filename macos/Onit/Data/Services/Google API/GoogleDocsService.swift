//
//  GoogleDocsService.swift
//  Onit
//
//  Created by Kévin Naudin on 07/01/2025.
//

import Foundation
import GoogleSignIn
import Defaults

struct TextWithOffsets {
    let reconstructedText: String
    let offsetToGoogleIndexMap: [Int: Int]
}

class GoogleDocsService: GoogleDocumentServiceProtocol {
    
    private let parser = GoogleDocsParser()
    
	var plainTextMimeType: String {
        return "text/plain"
    }
    
    func getPlainTextContent(fileId: String) async throws -> String {
        let structuredData = try await readStructuredFile(fileId: fileId)
        let document = try parser.parseGoogleDocsDocument(from: structuredData)
        let textWithOffsets = reconstructDocsTextWithOffsets(document: document)
        
        return textWithOffsets.reconstructedText
    }
    
    func updateFile(fileId: String, operations: [GoogleDocsOperation]) async throws {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleDriveServiceError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "https://docs.googleapis.com/v1/documents/\(fileId):batchUpdate"
        
        guard let url = URL(string: urlString) else {
            let error = "Invalid batchUpdate URL"
            
            throw GoogleDriveServiceError.invalidUrl(error)
        }

        var request = URLRequest(url: url)
        
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let innerRequests = convertToAPIRequests(operations: operations)
        let body: [String: Any] = [ "requests": innerRequests ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GoogleDriveServiceError.invalidResponse("Invalid response")
        }
    }
    
    func convertToAPIRequests(operations: [GoogleDocsOperation]) -> [[String: Any]] {
        var requests: [[String: Any]] = []
        
        for operation in operations {
            switch operation {
            case .insertText(let index, let text):
                requests.append([
                    "insertText": [
                        "location": ["index": index],
                        "text": text
                    ]
                ])
            case .deleteContentRange(let startIndex, let endIndex):
                requests.append([
                    "deleteContentRange": [
                        "range": [
                            "startIndex": startIndex,
                            "endIndex": endIndex
                        ]
                    ]
                ])
            case .replaceText(let startIndex, let endIndex, let newText):
                requests.append([
                    "deleteContentRange": [
                        "range": [
                            "startIndex": startIndex,
                            "endIndex": endIndex
                        ]
                    ]
                ])
                requests.append([
                    "insertText": [
                        "location": ["index": startIndex],
                        "text": newText
                    ]
                ])
            }
        }
        
        return requests
    }
    
    func applyDiffChanges(fileId: String, diffChanges: [DiffChangeData]) async throws {
        let structuredData = try await readStructuredFile(fileId: fileId)
        let document = try parser.parseGoogleDocsDocument(from: structuredData)
        let textWithOffsets = reconstructDocsTextWithOffsets(document: document)
        
        let sortedChanges = diffChanges.sorted { (change1, change2) in
            let pos1 = change1.operationStartIndex ?? change1.operationEndIndex ?? 0
            let pos2 = change2.operationStartIndex ?? change2.operationEndIndex ?? 0
            
            if pos1 == pos2 {
                let priority1 = operationPriority(change1.operationType)
                let priority2 = operationPriority(change2.operationType)
                return priority1 < priority2
            }
            
            return pos1 > pos2
        }
        
        let resolvedChanges = resolveOperationConflicts(sortedChanges)
        
        let googleDocsOperations = try mapDiffChangesToDocsOperations(
            diffChanges: resolvedChanges,
            offsetMap: textWithOffsets.offsetToGoogleIndexMap
        )
        
        try await updateFile(fileId: fileId, operations: googleDocsOperations)
    }
    
    private func operationPriority(_ type: String) -> Int {
        switch type {
        case "deleteContentRange": return 0  // Highest priority
        case "replaceText": return 1         // Medium priority  
        case "insertText": return 2          // Lowest priority
        default: return 3                    // Unknown operations last
        }
    }
    
    private func readStructuredFile(fileId: String) async throws -> [String: Any] {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleDriveServiceError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        let accessToken = user.accessToken.tokenString
        let apiUrl = "https://docs.googleapis.com/v1/documents/\(fileId)"
        
        guard let url = URL(string: apiUrl) else {
            throw GoogleDriveServiceError.invalidUrl("Invalid Google Docs API URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleDriveServiceError.invalidResponse("Invalid response")
        }
        
        if httpResponse.statusCode == 404 {
            throw GoogleDriveServiceError.notFound("Onit needs permission to access this file.")
        } else if httpResponse.statusCode == 403 {
            var errorMessage = "Onit can't access this file."
            if let errorData = String(data: data, encoding: .utf8) {
                errorMessage += "\n\nError message: \(errorData)"
            }
            throw GoogleDriveServiceError.accessDenied(errorMessage)
        } else if httpResponse.statusCode != 200 {
            var errorMessage = "Failed to retrieve document (HTTP \(httpResponse.statusCode))"
            if let errorData = String(data: data, encoding: .utf8) {
                errorMessage += "\n\nError message: \(errorData)"
            }
            throw GoogleDriveServiceError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GoogleDriveServiceError.decodingError("Failed to decode document content")
        }
        
        return json
    }
    
    // MARK: - Text Reconstruction with Offsets
    
    private func reconstructDocsTextWithOffsets(document: GoogleDocsDocument) -> TextWithOffsets {
        var reconstructedText = ""
        var offsetToGoogleIndexMap: [Int: Int] = [:]
        
        for element in document.body.content {
            let (elementText, elementMapping) = reconstructStructuralElement(
                element: element,
                startPosition: reconstructedText.count
            )
            
            for (textPos, googleIndex) in elementMapping {
                offsetToGoogleIndexMap[textPos] = googleIndex
            }
            
            reconstructedText += elementText
        }
        
        return TextWithOffsets(
            reconstructedText: reconstructedText,
            offsetToGoogleIndexMap: offsetToGoogleIndexMap
        )
    }
    
    private func reconstructStructuralElement(
        element: GoogleDocsStructuralElement,
        startPosition: Int
    ) -> (text: String, mapping: [Int: Int]) {
        var reconstructedText = ""
        var offsetToGoogleIndexMap: [Int: Int] = [:]
        
        if let paragraph = element.paragraph {
            for paragraphElement in paragraph.elements {
                if let textRun = paragraphElement.textRun {
                    let content = textRun.content
                    let currentStartPosition = startPosition + reconstructedText.count
                    
                    if let elementStartIndex = paragraphElement.startIndex {
                        let mappingResult = createTextToGoogleMapping(
                            content: content,
                            startPosition: currentStartPosition,
                            elementStartIndex: elementStartIndex
                        )
                        
                        for (textPos, googleIndex) in mappingResult.mapping {
                            offsetToGoogleIndexMap[textPos] = googleIndex
                        }
                        
                        reconstructedText += mappingResult.processedContent
                    } else {
                        reconstructedText += content
                    }
                } else {
                    if let elementStartIndex = paragraphElement.startIndex,
                       let placeholderChar = getPlaceholderCharacter(for: paragraphElement) {
                        let currentStartPosition = startPosition + reconstructedText.count
                        let mappingResult = createTextToGoogleMapping(
                            content: placeholderChar,
                            startPosition: currentStartPosition,
                            elementStartIndex: elementStartIndex
                        )
                        
                        for (textPos, googleIndex) in mappingResult.mapping {
                            offsetToGoogleIndexMap[textPos] = googleIndex
                        }
                        
                        reconstructedText += mappingResult.processedContent
                    }
                }
            }
        }
        
        if let table = element.table {
            for tableRow in table.tableRows {
                for tableCell in tableRow.tableCells {
                    for cellElement in tableCell.content {
                        let currentStartPosition = startPosition + reconstructedText.count
                        let (cellText, cellMapping) = reconstructStructuralElement(
                            element: cellElement,
                            startPosition: currentStartPosition
                        )
                        
                        for (textPos, googleIndex) in cellMapping {
                            offsetToGoogleIndexMap[textPos] = googleIndex
                        }
                        
                        reconstructedText += cellText
                    }
                }
            }
        }
        
        if let elementStartIndex = element.startIndex,
           let placeholderChar = getStructuralElementPlaceholderCharacter(for: element) {
            let currentStartPosition = startPosition + reconstructedText.count
            let mappingResult = createTextToGoogleMapping(
                content: placeholderChar,
                startPosition: currentStartPosition,
                elementStartIndex: elementStartIndex
            )
            
            for (textPos, googleIndex) in mappingResult.mapping {
                offsetToGoogleIndexMap[textPos] = googleIndex
            }
            
            reconstructedText += mappingResult.processedContent
        }
        
        return (reconstructedText, offsetToGoogleIndexMap)
    }
    
    private func createTextToGoogleMapping(
        content: String,
        startPosition: Int,
        elementStartIndex: Int
    ) -> (processedContent: String, mapping: [Int: Int]) {
        var mapping: [Int: Int] = [:]
        var processedContent = ""
        var textPosition = startPosition
        var googleIndex = elementStartIndex
        
        for char in content {
            if isInvisibleCharacter(char) {
                mapping[textPosition] = googleIndex
                googleIndex += 1
            } else if isGoogleDocsPlaceholderCharacter(char) {
				mapping[textPosition] = googleIndex
                googleIndex += 1
				textPosition += 1
			} else {
                mapping[textPosition] = googleIndex
                processedContent.append(char)
                textPosition += 1
                googleIndex += 1
            }
        }
        
        mapping[textPosition] = googleIndex
        
        return (processedContent, mapping)
    }
    
    private func isInvisibleCharacter(_ char: Character) -> Bool {
        let unicodeScalars = char.unicodeScalars
        for scalar in unicodeScalars {
            switch scalar.value {
            case 0xFEFF, // BOM (Byte Order Mark) / Zero Width No-Break Space
                 0x200B, // Zero Width Space
                 0x200C, // Zero Width Non-Joiner
                 0x200D, // Zero Width Joiner
                 0x2060, // Word Joiner
                 0x2063, // Invisible Separator
                 0x200E, // Left-to-right Mark
                 0x200F: // Right-to-left Mark
                return true
            default:
                continue
            }
        }
        return false
    }

	private func isGoogleDocsPlaceholderCharacter(_ char: Character) -> Bool {
		let unicodeScalars = char.unicodeScalars
		for scalar in unicodeScalars {
			switch scalar.value {
			case 0xE907, 0xE000, 0xE001, 0xE002, 0xE003, 0xE004, 0xE005, 0xE006, 0xE008, 0xE009:
				return true
			default:
				continue
			}
		}
		return false
	}
    
    private func getPlaceholderCharacter(for paragraphElement: GoogleDocsParagraphElement) -> String? {
        if paragraphElement.inlineObjectElement != nil {
            return "\u{E907}" // Images
        } else if paragraphElement.autoText != nil {
            return "\u{E000}" // AutoText (page numbers, etc.)
        } else if paragraphElement.columnBreak != nil {
            return "\u{E001}" // Column Break
        } else if paragraphElement.footnoteReference != nil {
            return "\u{E002}" // Footnote Reference
        } else if paragraphElement.horizontalRule != nil {
            return "\u{E003}" // Horizontal Rule
        } else if paragraphElement.equation != nil {
            return "\u{E004}" // Equation
        } else if paragraphElement.person != nil {
            return "\u{E005}" // Person
        } else if paragraphElement.richLink != nil {
            return "\u{E006}" // Rich Link
        }
        return nil
    }
    
    private func getStructuralElementPlaceholderCharacter(for element: GoogleDocsStructuralElement) -> String? {
        if element.pageBreak != nil {
            return "\u{000C}" // Page Break (form feed character)
        } else if element.sectionBreak != nil {
            return "\u{E008}" // Section Break
        } else if element.tableOfContents != nil {
            return "\u{E009}" // Table of Contents
        }
        return nil
    }
    
    // MARK: - Diff Changes to Google Docs Operations Mapping
    
    private func mapDiffChangesToDocsOperations(
        diffChanges: [DiffChangeData],
        offsetMap: [Int: Int]
    ) throws -> [GoogleDocsOperation] {
        var operations: [GoogleDocsOperation] = []
        
        for (_, change) in diffChanges.enumerated() {
            switch change.operationType {
            case "insertText":
                if let textPosition = change.operationStartIndex,
                   let text = change.operationText {
                    let googleIndex = getGoogleDocsIndex(for: textPosition, offsetMap: offsetMap)
                    
                    operations.append(.insertText(index: googleIndex, text: text))
                }
                
            case "deleteContentRange":
                if let startPosition = change.operationStartIndex,
                   let endPosition = change.operationEndIndex {
                    let startGoogleIndex = getGoogleDocsIndex(for: startPosition, offsetMap: offsetMap)
                    let endGoogleIndex = getGoogleDocsIndex(for: endPosition, offsetMap: offsetMap)
                    
                    operations.append(.deleteContentRange(startIndex: startGoogleIndex, endIndex: endGoogleIndex))
                }
                
            case "replaceText":
                if let startPosition = change.operationStartIndex,
                   let endPosition = change.operationEndIndex,
                   let newText = change.operationText {
                    let startGoogleIndex = getGoogleDocsIndex(for: startPosition, offsetMap: offsetMap)
                    let endGoogleIndex = getGoogleDocsIndex(for: endPosition, offsetMap: offsetMap)
                    
                    operations.append(.replaceText(startIndex: startGoogleIndex, endIndex: endGoogleIndex, newText: newText))
                }
                
            default:
                throw GoogleDriveServiceError.unsupportedFileType("Unknown operation type: \(change.operationType)")
            }
        }
        
        return operations
    }
    
    // MARK: - Operation Conflict Resolution
    
    private func resolveOperationConflicts(_ changes: [DiffChangeData]) -> [DiffChangeData] {
        var resolvedChanges: [DiffChangeData] = []
        
        for change in changes {
            switch change.operationType {
            case "deleteContentRange":
                resolvedChanges.append(change)
                
            case "insertText", "replaceText":
                let conflictsWithDelete = resolvedChanges.contains { deleteOp in
                    guard deleteOp.operationType == "deleteContentRange",
                          let deleteStart = deleteOp.operationStartIndex,
                          let deleteEnd = deleteOp.operationEndIndex,
                          let insertPos = change.operationStartIndex else {
                        return false
                    }
                    
                    return insertPos >= deleteStart && insertPos < deleteEnd
                }
                
                if conflictsWithDelete {
                    if let conflictingDelete = resolvedChanges.first(where: { deleteOp in
                        guard deleteOp.operationType == "deleteContentRange",
                              let deleteStart = deleteOp.operationStartIndex,
                              let deleteEnd = deleteOp.operationEndIndex,
                              let insertPos = change.operationStartIndex else {
                            return false
                        }
                        return insertPos >= deleteStart && insertPos < deleteEnd
                    }) {
                        let adjustedChange = DiffChangeData(
                            operationIndex: change.operationIndex,
                            operationType: change.operationType,
                            status: change.status,
                            operationText: change.operationText,
                            operationStartIndex: conflictingDelete.operationStartIndex,
                            operationEndIndex: change.operationEndIndex
                        )
                        
                        resolvedChanges.append(adjustedChange)
                    }
                } else {
                    resolvedChanges.append(change)
                }
                
            default:
                resolvedChanges.append(change)
            }
        }
        
        return resolvedChanges
    }
    
    // MARK: - Helper Methods
    
    private func getGoogleDocsIndex(for textPosition: Int, offsetMap: [Int: Int]) -> Int {
        if let exactIndex = offsetMap[textPosition] {
            return exactIndex
        }
        
        let sortedKeys = offsetMap.keys.sorted()
        
        var closestKey: Int? = nil
        for key in sortedKeys {
            if key <= textPosition {
                closestKey = key
            } else {
                break
            }
        }
        
        guard let baseKey = closestKey,
              let baseGoogleIndex = offsetMap[baseKey] else {
            return max(1, textPosition + 1)
        }
        
        let offset = textPosition - baseKey
        var nextKey: Int? = nil
        var nextGoogleIndex: Int? = nil
        
        for key in sortedKeys {
            if key > baseKey {
                nextKey = key
                nextGoogleIndex = offsetMap[key]
                break
            }
        }
        
        if let nextK = nextKey, let nextGIndex = nextGoogleIndex {
            let keyGap = nextK - baseKey
            let googleGap = nextGIndex - baseGoogleIndex
            
            if offset <= keyGap {
                let ratio = Double(offset) / Double(keyGap)
                let interpolatedGoogleIndex = baseGoogleIndex + Int(Double(googleGap) * ratio)
                
                return max(1, interpolatedGoogleIndex)
            } else {
                let extraOffset = offset - keyGap
                
                return max(1, nextGIndex + extraOffset)
            }
        } else {
            return max(1, baseGoogleIndex + offset)
        }
    }
}
