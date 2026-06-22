//
//  Memory.swift
//  Onit
//
//  Created by Kévin Naudin on 22/12/2025.
//

import Foundation
import GRDB
import SwiftUI

/// Represents a memory that the LLM will remember across sessions.
/// Memories are injected into the system prompt during generations.
struct Memory: Codable, Identifiable, Sendable, Equatable {

    /// Source of the memory creation
    enum Source: String, Codable, Sendable {
        case manual         // Created by user in UI
        case autoDetected   // Created by LLM via RememberTool
    }

    /// Unique identifier (auto-incremented by the database)
    let id: Int64?

    /// The memory text content
    var content: String

    /// Bundle identifier of the app this memory applies to.
    /// If nil, the memory is global and applies to all apps.
    var appBundleIdentifier: String?

    /// Whether the memory is enabled
    var isEnabled: Bool

    /// How the memory was created
    let source: Source

    /// Date when the memory was created
    let createdAt: Date

    // MARK: - Initialization

    init(
        id: Int64? = nil,
        content: String,
        appBundleIdentifier: String? = nil,
        isEnabled: Bool = true,
        source: Source = .manual,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.content = content
        self.appBundleIdentifier = appBundleIdentifier
        self.isEnabled = isEnabled
        self.source = source
        self.createdAt = createdAt
    }

    /// Returns true if the memory applies to all apps
    var isGlobal: Bool {
        appBundleIdentifier == nil
    }
}

// MARK: - UI Constants

extension Memory {
    /// Background color for the memory brain icon used throughout the app
    static let iconBackgroundColor = Color.purple
}

// MARK: - GRDB Extensions

extension Memory: FetchableRecord, PersistableRecord {
    static let databaseTableName = "memories"

    enum Columns: String, ColumnExpression {
        case id
        case content
        case appBundleIdentifier
        case isEnabled
        case source
        case createdAt
    }

    init(row: Row) throws {
        id = row[Columns.id]
        content = row[Columns.content]
        appBundleIdentifier = row[Columns.appBundleIdentifier]
        isEnabled = row[Columns.isEnabled]
        // Handle migration: default to .manual if source column doesn't exist
        if let sourceString: String = row[Columns.source] {
            source = Source(rawValue: sourceString) ?? .manual
        } else {
            source = .manual
        }
        createdAt = row[Columns.createdAt]
    }

    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.content] = content
        container[Columns.appBundleIdentifier] = appBundleIdentifier
        container[Columns.isEnabled] = isEnabled
        container[Columns.source] = source.rawValue
        container[Columns.createdAt] = createdAt
    }
}
