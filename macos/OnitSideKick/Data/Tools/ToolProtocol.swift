//
//  ToolProtocol.swift
//  Onit
//
//  Created by Kévin Naudin on 07/22/2025.
//

/// Context passed to tools during execution
struct ToolContext: Sendable {
    /// Bundle identifier of the current app (from tracked window)
    let appBundleIdentifier: String?

    static let empty = ToolContext(appBundleIdentifier: nil)
}

@MainActor
protocol ToolProtocol {
    typealias ToolCallResultAlias = Result<ToolCallResult, ToolCallError>
    
    var activeTools: [Tool] { get }
    func canExecute(partialArguments: String) -> Bool
    func execute(toolName: String, arguments: String, context: ToolContext) async -> ToolCallResultAlias
}
