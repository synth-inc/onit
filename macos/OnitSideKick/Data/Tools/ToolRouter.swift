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
    private static let rememberTool = RememberTool()
    
    @MainActor
    static var activeTools: [Tool] {
        return rememberTool.activeTools
    }

    @MainActor
    static func parseAndExecuteToolCalls(
        toolName: String,
        toolArguments: String,
        isComplete: Bool,
        context: ToolContext = .empty
    ) async -> Result<ToolCallResult, ToolCallError>? {
        guard let (appName, parsedToolName) = parseToolName(toolName: toolName) else {
            log.error("[ToolRouter] Unable to parse tool name: \(toolName)")
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
        case "memory":
            tool = rememberTool
        default:
            tool = nil
        }
        
        guard let tool = tool else {
            return .failure(
                ToolCallError(toolName: toolName, message: "Unrecognized app name: \(appName)")
            )
        }
        
        if !isComplete && !tool.canExecute(partialArguments: toolArguments) {
            return nil
        } else {
            return await tool.execute(toolName: parsedToolName, arguments: toolArguments, context: context)
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
