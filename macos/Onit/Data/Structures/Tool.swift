//
//  Tool.swift
//  Onit
//
//  Created by Jay Swanson on 6/12/25.
//

import Foundation

struct Tool: Codable {
    let name: String
    let description: String
    let parameters: ToolParameters
}

struct ToolParameters: Codable {
    let properties: [String: ToolProperty]
    let required: [String]
}

struct ToolProperty: Codable {
    let type: String
    let description: String
    let items: ToolPropertyItem?
}

struct ToolPropertyItem: Codable {
    let type: String
}

struct ToolCallResult {
    let toolName: String
    let result: String
}

struct ToolCallError: Error {
    let toolName: String?
    let message: String
}
