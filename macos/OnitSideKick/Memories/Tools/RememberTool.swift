//
//  RememberTool.swift
//  Onit
//
//  Created by Kévin Naudin on 22/12/2025.
//

import Defaults
import Foundation

/// Tool that allows the LLM to save important user preferences as memories
@MainActor
final class RememberTool: ToolProtocol {

    // MARK: - Tool Definition

    static let toolName = "remember"
    static let fullToolName = "memory_remember"

    var activeTools: [Tool] {
        // Only provide the tool if both memories and auto-detection are enabled
        guard Defaults[.memoriesEnabled], Defaults[.memoryAutoDetectionEnabled] else {
            return []
        }

        return [
            Tool(
                name: Self.fullToolName,
                description: """
                    Save a user preference ONLY when explicitly requested by the user.

                    USE this tool when the user says things like:
                    - "Remember that I prefer..."
                    - "Always do X from now on"
                    - "Keep in mind that..."
                    - "Note that I like..."

                    DO NOT use this tool for:
                    - Normal questions or tasks
                    - Information mentioned in passing
                    - Context about other people (colleagues, friends)
                    - Temporary or one-time information

                    Only save permanent user preferences that apply to future conversations.
                    """,
                parameters: ToolParameters(
                    properties: [
                        "content": ToolProperty(
                            type: "string",
                            description: "The information to remember, written as a concise statement (e.g., 'User prefers Swift over Objective-C')",
                            items: nil
                        ),
                        "scope": ToolProperty(
                            type: "string",
                            description: "Where this memory applies: 'global' (all apps) or 'current_app' (only the current application). Default is 'current_app'.",
                            items: nil
                        ),
                        "reason": ToolProperty(
                            type: "string",
                            description: "Brief explanation of why this is worth remembering",
                            items: nil
                        )
                    ],
                    required: ["content"]
                )
            )
        ]
    }

    // MARK: - Execution

    func canExecute(partialArguments: String) -> Bool {
        // Never execute early - wait for complete arguments to avoid duplicate saves
        return false
    }

    func execute(toolName: String, arguments: String, context: ToolContext) async -> ToolCallResultAlias {
        guard toolName == Self.toolName else {
            return .failure(ToolCallError(toolName: toolName, message: "Unknown tool: \(toolName)"))
        }

        // Parse arguments
        guard let data = arguments.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? String else {
            return .failure(ToolCallError(toolName: toolName, message: "Invalid arguments: expected JSON with 'content' field"))
        }

        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            return .failure(ToolCallError(toolName: toolName, message: "Content cannot be empty"))
        }

        // Determine scope: "global" or "current_app" (default)
        let scope = (json["scope"] as? String)?.lowercased() ?? "current_app"
        let appBundleIdentifier: String? = (scope == "global") ? nil : context.appBundleIdentifier

        // Create the memory with source = .autoDetected
        let memory = Memory(
            content: trimmedContent,
            appBundleIdentifier: appBundleIdentifier,
            source: .autoDetected
        )

        do {
            try await MemoryManager.shared.create(memory)

            let reason = json["reason"] as? String ?? "User preference detected"
            let scopeDescription = appBundleIdentifier != nil ? "current app" : "all apps"
            return .success(ToolCallResult(
                toolName: toolName,
                result: "Memory saved: \"\(trimmedContent)\" (Scope: \(scopeDescription), Reason: \(reason))"
            ))
        } catch {
            return .failure(ToolCallError(toolName: toolName, message: "Failed to save memory: \(error.localizedDescription)"))
        }
    }
}
