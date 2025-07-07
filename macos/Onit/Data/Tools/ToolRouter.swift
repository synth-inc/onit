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

    static func parseAndExecuteToolCalls(functionName: String, functionArguments: String) async
        -> Result<ToolCallResult, ToolCallError>
    {
        let nameParts = functionName.split(separator: "_")
        if nameParts.count < 2 {
            return .failure(
                ToolCallError(
                    toolName: nil, message: "Unable to parse function name: \(functionName)"))
        }
        let appName = String(nameParts[0])
        let toolName = String(functionName.dropFirst(appName.count + 1))
        switch appName {
        case "calendar":
            return await CalendarTool.executeToolCall(
                toolName: toolName, arguments: functionArguments)
        case "diff":
            return await DiffTool.executeToolCall(
                toolName: toolName, arguments: functionArguments)
        default:
            return .failure(
                ToolCallError(toolName: functionName, message: "Unrecognized app name: \(appName)"))
        }
    }
}
