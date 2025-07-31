//
//  StreamToolAccumulator.swift
//  Onit
//
//  Created by Kévin Naudin on 07/07/2025.
//

import Foundation

class StreamToolAccumulator: @unchecked Sendable {
    private var currentToolName: String?
    private var accumulatedArguments: String = ""
    
    func startTool(name: String) -> StreamingEndpointResponse {
        currentToolName = name
        accumulatedArguments = ""
        
        return StreamingEndpointResponse(content: nil,
                                         toolName: name,
                                         toolArguments: nil,
                                         isToolComplete: false)
    }
    
    func addArguments(_ fragment: String) -> StreamingEndpointResponse {
        accumulatedArguments += fragment
        
        // Create a valid JSON by completing the partial JSON
        let validJSON = makeValidJSON(from: accumulatedArguments)
        
        return StreamingEndpointResponse(content: nil,
                                         toolName: currentToolName,
                                         toolArguments: validJSON,
                                         isToolComplete: false)
    }
    
    func finishTool() -> StreamingEndpointResponse {
        let toolName = currentToolName
        let arguments = accumulatedArguments
        
        currentToolName = nil
        accumulatedArguments = ""
        
        return StreamingEndpointResponse(content: nil,
                                         toolName: toolName,
                                         toolArguments: arguments,
                                         isToolComplete: true)
    }
    
    func hasActiveTool() -> Bool {
        return currentToolName != nil
    }
    
    // MARK: - JSON Validation
    
    private func makeValidJSON(from partialJSON: String) -> String {
		if isValidJSON(partialJSON) {
			return partialJSON
		}

		var cleanedJSON = partialJSON.trimmingCharacters(in: .whitespacesAndNewlines)

		if !cleanedJSON.hasPrefix("{") && !cleanedJSON.hasPrefix("[") {
			cleanedJSON = "{" + cleanedJSON
		}

		var openBraces = 0
		var openBrackets = 0
		var openQuotes = false
		var i = cleanedJSON.startIndex

		while i < cleanedJSON.endIndex {
			let char = cleanedJSON[i]

			if char == "\"" {
				let previousIndex = cleanedJSON.index(before: i)
				let isEscaped = previousIndex > cleanedJSON.startIndex && cleanedJSON[previousIndex] == "\\" && cleanedJSON[cleanedJSON.index(before: previousIndex)] != "\\"
				if !isEscaped {
					openQuotes.toggle()
				}
			}

			if !openQuotes {
				switch char {
				case "{":
					openBraces += 1
				case "}":
					openBraces = max(0, openBraces - 1)
				case "[":
					openBrackets += 1
				case "]":
					openBrackets = max(0, openBrackets - 1)
				default:
					break
				}
			}

			i = cleanedJSON.index(after: i)
		}

		if openQuotes {
			cleanedJSON += "\""
		}

		let lastNonWS = cleanedJSON.last { !$0.isWhitespace }
		
		if let lastColonIndex = cleanedJSON.lastIndex(of: ":") {
			let suffix = cleanedJSON[lastColonIndex...].trimmingCharacters(in: .whitespacesAndNewlines)
			if suffix == ":" {
				cleanedJSON += "\"\""
			} else if suffix.hasSuffix(":\"") && !suffix.hasSuffix(":\"\"") {
				cleanedJSON += "\""
			}
		} else {
			if lastNonWS == "\"" {
				if let lastQuoteIndex = cleanedJSON.lastIndex(of: "\"") {
					let beforeQuote = cleanedJSON[..<lastQuoteIndex].reversed()
					
					var foundStructure = false
					for char in beforeQuote {
						if char == "," || char == "{" {
							foundStructure = true
							break
						} else if char == ":" {
							foundStructure = false
							break
						} else if !char.isWhitespace {
							continue
						}
					}
					
					if foundStructure {
						cleanedJSON += "\":\"\""
					}
				}
			} else if lastNonWS == "," || lastNonWS == "{" {
				cleanedJSON += "\"__stream_placeholder\":true"
			} else if lastNonWS == "[" {
				cleanedJSON += "null"
			} else {
				if let lastBraceIndex = cleanedJSON.lastIndex(where: { $0 == "{" || $0 == "," }) {
					let potentialKey = cleanedJSON[cleanedJSON.index(after: lastBraceIndex)...]
						.trimmingCharacters(in: .whitespacesAndNewlines)
					
					if !potentialKey.isEmpty && 
					   potentialKey.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) &&
					   !potentialKey.contains(":") {
						cleanedJSON = String(cleanedJSON[...lastBraceIndex])
						cleanedJSON += "\"\(potentialKey)\":\"\""
					}
				}
			}
		}

		cleanedJSON += String(repeating: "]", count: openBrackets)
		cleanedJSON += String(repeating: "}", count: openBraces)

		if isValidJSON(cleanedJSON) {
			return cleanedJSON
		}

		return "{\"_rawPartial\":\"\(escapeJSONString(partialJSON))\"}"
	}

	private func isValidJSON(_ string: String) -> Bool {
		guard let data = string.data(using: .utf8) else { return false }
		return (try? JSONSerialization.jsonObject(with: data)) != nil
	}

	private func escapeJSONString(_ string: String) -> String {
		return string
			.replacingOccurrences(of: "\\", with: "\\\\")
			.replacingOccurrences(of: "\"", with: "\\\"")
			.replacingOccurrences(of: "\n", with: "\\n")
			.replacingOccurrences(of: "\r", with: "\\r")
			.replacingOccurrences(of: "\t", with: "\\t")
	}
}
