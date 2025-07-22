//
//  ToolProtocol.swift
//  Onit
//
//  Created by Kévin Naudin on 07/22/2025.
//

protocol ToolProtocol {
    typealias ToolCallResultAlias = Result<ToolCallResult, ToolCallError>
    
    var activeTools: [Tool] { get }
    func canExecute(partialArguments: String) -> Bool
    func execute(toolName: String, arguments: String) async -> ToolCallResultAlias
}
