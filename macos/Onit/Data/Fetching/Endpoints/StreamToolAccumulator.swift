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
        
        return StreamingEndpointResponse(content: nil,
                                         toolName: currentToolName,
                                         toolArguments: accumulatedArguments,
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
}
