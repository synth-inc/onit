//
//  ToolRouter.swift
//  Onit
//
//  Created by Jay Swanson on 6/12/25.
//

import Foundation

actor ToolRouter {
    @MainActor
    static var activeTools: [Tool] {
        return CalendarTool.activeTools + DiffTool.activeTools
    }

    static func parseAndExecuteToolCalls(toolName: String, toolArguments: String) async
        -> Result<ToolCallResult, ToolCallError>
    {
        let nameParts = toolName.split(separator: "_")
        if nameParts.count < 2 {
            return .failure(
                ToolCallError(
                    toolName: nil, message: "Unable to parse tool name: \(toolName)"))
        }
        let appName = String(nameParts[0])
        let toolName = String(toolName.dropFirst(appName.count + 1))
        switch appName {
        case "calendar":
            return await CalendarTool.executeToolCall(
                toolName: toolName, arguments: toolArguments)
        case "diff":
            return await DiffTool.executeToolCall(
                toolName: toolName, arguments: toolArguments)
        default:
            return .failure(
                ToolCallError(toolName: toolName, message: "Unrecognized app name: \(appName)"))
        }
    }
}
