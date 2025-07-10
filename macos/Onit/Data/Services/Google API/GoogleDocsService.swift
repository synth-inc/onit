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
    
	var plainTextMimeType: String {
        return "text/plain"
    }
    
    func getPlainTextContent(fileId: String) async throws -> String {
        let structuredData = try await readStructuredFile(fileId: fileId)
        let document = try parseGoogleDocsDocument(from: structuredData)
        let textWithOffsets = reconstructDocsTextWithOffsets(document: document)
        
        return textWithOffsets.reconstructedText
    }
    
    func updateFile(fileId: String, operations: [GoogleDocsOperation]) async throws {
        guard let user = GIDSignIn.sharedInstance.currentUser else {
            throw GoogleDriveError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        let accessToken = user.accessToken.tokenString
        let urlString = "https://docs.googleapis.com/v1/documents/\(fileId):batchUpdate"
        
        guard let url = URL(string: urlString) else {
            let error = "Invalid batchUpdate URL"
            
            throw GoogleDriveError.invalidUrl(error)
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
            throw GoogleDriveError.invalidResponse("Invalid response")
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
        let document = try parseGoogleDocsDocument(from: structuredData)
        let textWithOffsets = reconstructDocsTextWithOffsets(document: document)
        
        let sortedChanges = diffChanges.sorted { (change1, change2) in
            let pos1 = change1.operationStartIndex ?? change1.operationEndIndex ?? 0
            let pos2 = change2.operationStartIndex ?? change2.operationEndIndex ?? 0
            
            if pos1 == pos2 {
                let priority1 = operationPriority(change1.operationType)
                let priority2 = operationPriority(change2.operationType)
                return priority1 < priority2
            }
            
            return pos1 < pos2
        }
        
        log.debug("Applying \(sortedChanges.count) diff changes to Google Docs")
        
        let googleDocsOperations = try mapDiffChangesToDocsOperations(
            diffChanges: sortedChanges,
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
            throw GoogleDriveError.notAuthenticated("Not authenticated with Google Drive")
        }
        
        let accessToken = user.accessToken.tokenString
        let apiUrl = "https://docs.googleapis.com/v1/documents/\(fileId)"
        
        guard let url = URL(string: apiUrl) else {
            throw GoogleDriveError.invalidUrl("Invalid Google Docs API URL")
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GoogleDriveError.invalidResponse("Invalid response")
        }
        
        if httpResponse.statusCode == 404 {
            throw GoogleDriveError.notFound("Onit needs permission to access this file.")
        } else if httpResponse.statusCode == 403 {
            var errorMessage = "Onit can't access this file."
            if let errorData = String(data: data, encoding: .utf8) {
                errorMessage += "\n\nError message: \(errorData)"
            }
            throw GoogleDriveError.accessDenied(errorMessage)
        } else if httpResponse.statusCode != 200 {
            var errorMessage = "Failed to retrieve document (HTTP \(httpResponse.statusCode))"
            if let errorData = String(data: data, encoding: .utf8) {
                errorMessage += "\n\nError message: \(errorData)"
            }
            throw GoogleDriveError.httpError(httpResponse.statusCode, errorMessage)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GoogleDriveError.decodingError("Failed to decode document content")
        }
        
        return json
    }
    
    // MARK: - Text Reconstruction with Offsets
    
    private func reconstructDocsTextWithOffsets(document: GoogleDocsDocument) -> TextWithOffsets {
        var reconstructedText = ""
        var offsetToGoogleIndexMap: [Int: Int] = [:]
        
        for element in document.body.content {
            if let paragraph = element.paragraph {
                for paragraphElement in paragraph.elements {
                    if let textRun = paragraphElement.textRun {
                        let content = textRun.content
                        
                        // Map each character position in reconstructed text to Google Docs index
                        // Note: Google Docs body content starts at index 1, not 0
                        let startPosition = reconstructedText.count
                        
                        if let elementStartIndex = paragraphElement.startIndex {
                            // Create mapping that handles invisible characters
                            let mappingResult = createTextToGoogleMapping(
                                content: content,
                                startPosition: startPosition,
                                elementStartIndex: elementStartIndex
                            )
                            
                            // Merge the mapping into the global offset map
                            for (textPos, googleIndex) in mappingResult.mapping {
                                offsetToGoogleIndexMap[textPos] = googleIndex
                            }
                            
                            reconstructedText += mappingResult.processedContent
                        } else {
                            // Fallback for elements without startIndex
                            reconstructedText += content
                        }
                    }
                }
            }
            // Handle other element types (tables, page breaks) if needed
        }
        
        log.debug("Reconstructed text:\n\(reconstructedText)")
        log.debug("Offset map: \(offsetToGoogleIndexMap)")
        
        return TextWithOffsets(
            reconstructedText: reconstructedText,
            offsetToGoogleIndexMap: offsetToGoogleIndexMap
        )
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
                // For invisible characters: map the current text position to the Google index,
                // but don't add to processed content and advance Google index
                mapping[textPosition] = googleIndex
                googleIndex += 1
            } else {
                // For visible characters: map and add to processed content
                mapping[textPosition] = googleIndex
                processedContent.append(char)
                textPosition += 1
                googleIndex += 1
            }
        }
        
        // Map the end position (for insertions at the end)
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
    
    // MARK: - Diff Changes to Google Docs Operations Mapping
    
    private func mapDiffChangesToDocsOperations(
        diffChanges: [DiffChangeData],
        offsetMap: [Int: Int]
    ) throws -> [GoogleDocsOperation] {
        var operations: [GoogleDocsOperation] = []
        var cumulativeOffset = 0 // Track the cumulative offset from previous operations
        
        // Changes are already sorted in ascending order in applyDiffChanges
        for change in diffChanges {
            switch change.operationType {
            case "insertText":
                // For insertText, DiffChangeState stores the insertion position in operationStartIndex
                if let textPosition = change.operationStartIndex,
                   let text = change.operationText {
                    let googleIndex = getGoogleDocsIndex(for: textPosition, offsetMap: offsetMap) + cumulativeOffset
                    operations.append(.insertText(index: googleIndex, text: text))
                    log.debug("Insert operation: position \(textPosition) + offset \(cumulativeOffset) -> Google index \(googleIndex), text: '\(text)'")
                    
                    // Update cumulative offset: insertion adds text length
                    cumulativeOffset += text.count
                }
                
            case "deleteContentRange":
                if let startPosition = change.operationStartIndex,
                   let endPosition = change.operationEndIndex {
                    let startGoogleIndex = getGoogleDocsIndex(for: startPosition, offsetMap: offsetMap) + cumulativeOffset
                    let endGoogleIndex = getGoogleDocsIndex(for: endPosition, offsetMap: offsetMap) + cumulativeOffset
                    operations.append(.deleteContentRange(startIndex: startGoogleIndex, endIndex: endGoogleIndex))
                    log.debug("Delete operation: positions \(startPosition)-\(endPosition) + offset \(cumulativeOffset) -> Google indices \(startGoogleIndex)-\(endGoogleIndex)")
                    
                    // Update cumulative offset: deletion removes text length
                    cumulativeOffset -= (endPosition - startPosition)
                }
                
            case "replaceText":
                if let startPosition = change.operationStartIndex,
                   let endPosition = change.operationEndIndex,
                   let newText = change.operationText {
                    let startGoogleIndex = getGoogleDocsIndex(for: startPosition, offsetMap: offsetMap) + cumulativeOffset
                    let endGoogleIndex = getGoogleDocsIndex(for: endPosition, offsetMap: offsetMap) + cumulativeOffset
                    operations.append(.replaceText(startIndex: startGoogleIndex, endIndex: endGoogleIndex, newText: newText))
                    log.debug("Replace operation: positions \(startPosition)-\(endPosition) + offset \(cumulativeOffset) -> Google indices \(startGoogleIndex)-\(endGoogleIndex), text: '\(newText)'")
                    
                    // Update cumulative offset: replace changes text length
                    let deletedLength = endPosition - startPosition
                    let insertedLength = newText.count
                    cumulativeOffset += (insertedLength - deletedLength)
                }
                
            default:
                throw GoogleDriveError.unsupportedFileType("Unknown operation type: \(change.operationType)")
            }
        }
        
        return operations
    }
    
    // MARK: - Helper Methods
    
    private func getGoogleDocsIndex(for textPosition: Int, offsetMap: [Int: Int]) -> Int {
        // First try to get exact mapping
        if let exactIndex = offsetMap[textPosition] {
            return exactIndex
        }
        
        // If no exact mapping, find the closest valid position
        // This handles edge cases where diff positions don't align perfectly with element boundaries
        let sortedKeys = offsetMap.keys.sorted()
        
        // Find the position just before or at the target position
        var closestKey = 1 // Default to beginning of body content (index 1)
        for key in sortedKeys {
            if key <= textPosition {
                closestKey = key
            } else {
                break
            }
        }
        
        // Calculate the offset difference and apply it to the Google Docs index
        if let baseGoogleIndex = offsetMap[closestKey] {
            let offset = textPosition - closestKey
            return max(1, baseGoogleIndex + offset) // Ensure minimum index is 1
        }
        
        // Fallback: use the last known position + 1
        if let lastKey = sortedKeys.last,
           let lastGoogleIndex = offsetMap[lastKey] {
            return lastGoogleIndex + (textPosition - lastKey) + 1
        }
        
        // Ultimate fallback: start at body beginning
        return max(1, textPosition + 1)
    }
    
    // MARK: - Document Parser
    
    private func parseGoogleDocsDocument(from data: [String: Any]) throws -> GoogleDocsDocument {
        guard let documentId = data["documentId"] as? String,
              let title = data["title"] as? String,
              let bodyData = data["body"] as? [String: Any],
              let revisionId = data["revisionId"] as? String else {
            throw GoogleDriveError.invalidResponse("Invalid Google Docs document structure")
        }
        
        let body = try parseGoogleDocsBody(from: bodyData)
        
        return GoogleDocsDocument(
            documentId: documentId,
            title: title,
            body: body,
            revisionId: revisionId
        )
    }
    
    private func parseGoogleDocsBody(from data: [String: Any]) throws -> GoogleDocsBody {
        guard let contentArray = data["content"] as? [[String: Any]] else {
            throw GoogleDriveError.invalidResponse("Invalid Google Docs body structure")
        }
        
        let content = contentArray.compactMap { elementData in
            return parseGoogleDocsStructuralElement(from: elementData)
        }
        
        return GoogleDocsBody(content: content)
    }
    
    private func parseGoogleDocsStructuralElement(from data: [String: Any]) -> GoogleDocsStructuralElement? {
        let startIndex = data["startIndex"] as? Int
        let endIndex = data["endIndex"] as? Int
        
        var paragraph: GoogleDocsParagraph?
        var table: GoogleDocsTable?
        var pageBreak: GoogleDocsPageBreak?
        
        if let paragraphData = data["paragraph"] as? [String: Any] {
            paragraph = parseGoogleDocsParagraph(from: paragraphData)
        }
        
        if let tableData = data["table"] as? [String: Any] {
            table = parseGoogleDocsTable(from: tableData)
        }
        
        if data["pageBreak"] != nil {
            pageBreak = GoogleDocsPageBreak()
        }
        
        return GoogleDocsStructuralElement(
            startIndex: startIndex,
            endIndex: endIndex,
            paragraph: paragraph,
            table: table,
            pageBreak: pageBreak
        )
    }
    
    private func parseGoogleDocsParagraphElement(from data: [String: Any]) -> GoogleDocsParagraphElement? {
        let startIndex = data["startIndex"] as? Int
        let endIndex = data["endIndex"] as? Int
        
        var textRun: GoogleDocsTextRun?
        if let textRunData = data["textRun"] as? [String: Any],
           let content = textRunData["content"] as? String {
            textRun = GoogleDocsTextRun(content: content)
        }
        
        return GoogleDocsParagraphElement(
            startIndex: startIndex,
            endIndex: endIndex,
            textRun: textRun
        )
    }
    
    private func parseGoogleDocsParagraph(from data: [String: Any]) -> GoogleDocsParagraph? {
        guard let elementsArray = data["elements"] as? [[String: Any]] else {
            return nil
        }
        
        let elements = elementsArray.compactMap { elementData in
            return parseGoogleDocsParagraphElement(from: elementData)
        }
        
        return GoogleDocsParagraph(elements: elements)
    }
    
    private func parseGoogleDocsTable(from data: [String: Any]) -> GoogleDocsTable? {
        let rows = data["rows"] as? Int ?? 0
        let columns = data["columns"] as? Int ?? 0
        
        var tableRows: [GoogleDocsTableRow] = []
        if let tableRowsData = data["tableRows"] as? [[String: Any]] {
            tableRows = tableRowsData.compactMap { parseGoogleDocsTableRow(from: $0) }
        }
        
        return GoogleDocsTable(
            rows: rows,
            columns: columns,
            tableRows: tableRows
        )
    }
    
    private func parseGoogleDocsTableRow(from data: [String: Any]) -> GoogleDocsTableRow? {
        var tableCells: [GoogleDocsTableCell] = []
        if let tableCellsData = data["tableCells"] as? [[String: Any]] {
            tableCells = tableCellsData.compactMap { parseGoogleDocsTableCell(from: $0) }
        }
        
        return GoogleDocsTableRow(tableCells: tableCells)
    }
    
    private func parseGoogleDocsTableCell(from data: [String: Any]) -> GoogleDocsTableCell? {
        var content: [GoogleDocsStructuralElement] = []
        if let contentData = data["content"] as? [[String: Any]] {
            // Recursively parse table cell content (can contain paragraphs)
            content = contentData.compactMap { parseGoogleDocsStructuralElement(from: $0) }
        }
        
        return GoogleDocsTableCell(content: content)
    }
}
