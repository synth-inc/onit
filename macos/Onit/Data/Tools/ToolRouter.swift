//
//  ToolRouter.swift
//  Onit
//
//  Created by Jay Swanson on 6/12/25.
//

import Foundation

actor ToolRouter {
    
    private static let calendarTool = CalendarTool()
    private static let diffTool = DiffTool()
    
    @MainActor
    static var activeTools: [Tool] {
        #if DEBUG || BETA
        return calendarTool.activeTools + diffTool.activeTools
        #else
        return []
        #endif
    }

    static func parseAndExecuteToolCalls(
        toolName: String,
        toolArguments: String,
        isComplete: Bool
    ) async -> Result<ToolCallResult, ToolCallError>? {
        guard let (appName, toolName) = parseToolName(toolName: toolName) else {
            return .failure(
                ToolCallError(toolName: nil, message: "Unable to parse tool name: \(toolName)")
            )
        }
        
        let tool: ToolProtocol?
        
        switch appName {
        case "calendar":
            tool = calendarTool
        case "diff":
            tool = diffTool
        default:
            tool = nil
        }
        
        guard let tool = tool else {
            return .failure(
                ToolCallError(toolName: toolName, message: "Unrecognized tool name: \(appName)")
            )
        }
        
        if !isComplete && !tool.canExecute(partialArguments: toolArguments) {
            return nil
        } else {
            return await tool.execute(toolName: toolName, arguments: toolArguments)
        }
    }
    
    private static func parseToolName(toolName: String) -> (appName: String, toolName: String)? {
        let nameParts = toolName.split(separator: "_")

        if nameParts.count < 2 {
            return nil
        }
        
        let appName = String(nameParts[0])
        
        return (appName: appName, toolName: String(toolName.dropFirst(appName.count + 1)))
    }
}
