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
    
    func startTool(name: String) {
        currentToolName = name
        accumulatedArguments = ""
    }
    
    func addArguments(_ fragment: String) {
        accumulatedArguments += fragment
    }
    
    func finishTool() -> (name: String, arguments: String)? {
        guard let toolName = currentToolName else { return nil }
        let arguments = accumulatedArguments
        
        currentToolName = nil
        accumulatedArguments = ""
        
        return (name: toolName, arguments: arguments)
    }
    
    func hasActiveTool() -> Bool {
        return currentToolName != nil
    }
}
