//
//  MemoryManager.swift
//  Onit
//
//  Created by Kévin Naudin on 22/12/2025.
//

import Foundation
import GRDB

/// Manages the Memory database for storing user preferences across sessions.
/// Singleton pattern following QuickEditPromptHistoryManager.
final class MemoryManager: ObservableObject, @unchecked Sendable {

    // MARK: - Singleton

    @MainActor
    static let shared = MemoryManager()

    // MARK: - Database

    private var dbQueue: DatabaseQueue?
    private let dbFile: String = "memories.sqlite"

    private var dbPath: String? {
        let fileManager = FileManager.default

        guard let applicationSupportURL = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first else {
            return nil
        }

        let onitURL = applicationSupportURL.appendingPathComponent("Onit")
        try? fileManager.createDirectory(at: onitURL, withIntermediateDirectories: true)

        return onitURL.appendingPathComponent(dbFile).path
    }

    // MARK: - Published

    @MainActor
    @Published var memoriesCount: Int = 0

    // MARK: - Initialization

    private init() {
        setupDatabase()
    }

    private func setupDatabase() {
        guard let dbPath = dbPath else {
            log.error("[MemoryManager] Could not determine database path")
            return
        }

        do {
            dbQueue = try DatabaseQueue(path: dbPath)

            try dbQueue?.write { db in
                try createTables(in: db)
                try createIndexes(in: db)
            }

            log.info("[MemoryManager] Database setup complete")
        } catch {
            log.error("[MemoryManager] Database setup failed: \(error)")
        }
    }

    private func createTables(in db: Database) throws {
        try db.create(table: Memory.databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("content", .text).notNull()
            t.column("appBundleIdentifier", .text)
            t.column("isEnabled", .boolean).notNull().defaults(to: true)
            t.column("source", .text).notNull().defaults(to: Memory.Source.manual.rawValue)
            t.column("createdAt", .datetime).notNull()
        }

        // Migration: add source column if it doesn't exist (for existing databases)
        if try db.columns(in: Memory.databaseTableName).first(where: { $0.name == "source" }) == nil {
            try db.alter(table: Memory.databaseTableName) { t in
                t.add(column: "source", .text).notNull().defaults(to: Memory.Source.manual.rawValue)
            }
        }
    }

    private func createIndexes(in db: Database) throws {
        try db.create(
            index: "idx_memory_bundle",
            on: Memory.databaseTableName,
            columns: ["appBundleIdentifier"],
            ifNotExists: true
        )

        try db.create(
            index: "idx_memory_enabled",
            on: Memory.databaseTableName,
            columns: ["isEnabled"],
            ifNotExists: true
        )
    }

    // MARK: - CRUD Operations

    /// Creates a new memory in the database
    /// - Parameter memory: The memory to create
    nonisolated func create(_ memory: Memory) async throws {
        guard let dbQueue = dbQueue else { return }

        try await dbQueue.write { db in
            var newMemory = memory
            try newMemory.insert(db)
        }

        await updateMemoriesCount()
    }

    /// Fetches all memories from the database
    /// - Returns: Array of all memories, ordered by creation date descending
    nonisolated func fetchAll() async -> [Memory] {
        guard let dbQueue = dbQueue else { return [] }

        do {
            return try await dbQueue.read { db in
                try Memory
                    .order(Memory.Columns.createdAt.desc)
                    .fetchAll(db)
            }
        } catch {
            log.error("[MemoryManager] fetchAll failed: \(error)")
            return []
        }
    }

    /// Fetches enabled memories applicable for a given app
    /// - Parameter bundleIdentifier: The app's bundle identifier. If nil, only global memories are returned.
    /// - Returns: Array of enabled memories (global + app-specific if bundleIdentifier is provided)
    nonisolated func fetchForApp(bundleIdentifier: String?) async -> [Memory] {
        guard let dbQueue = dbQueue else { return [] }

        do {
            return try await dbQueue.read { db in
                if let bundleId = bundleIdentifier {
                    // Global memories + app-specific memories
                    return try Memory
                        .filter(Memory.Columns.isEnabled == true)
                        .filter(
                            Memory.Columns.appBundleIdentifier == nil ||
                            Memory.Columns.appBundleIdentifier == bundleId
                        )
                        .order(Memory.Columns.createdAt.desc)
                        .fetchAll(db)
                } else {
                    // Only global memories
                    return try Memory
                        .filter(Memory.Columns.isEnabled == true)
                        .filter(Memory.Columns.appBundleIdentifier == nil)
                        .order(Memory.Columns.createdAt.desc)
                        .fetchAll(db)
                }
            }
        } catch {
            log.error("[MemoryManager] fetchForApp failed: \(error)")
            return []
        }
    }

    /// Updates an existing memory in the database
    /// - Parameter memory: The memory to update (must have a valid id)
    nonisolated func update(_ memory: Memory) async throws {
        guard let dbQueue = dbQueue else { return }

        try await dbQueue.write { db in
            try memory.update(db)
        }
    }

    /// Deletes a memory from the database
    /// - Parameter id: The ID of the memory to delete
    nonisolated func delete(id: Int64) async throws {
        guard let dbQueue = dbQueue else { return }

        try await dbQueue.write { db in
            try Memory
                .filter(Memory.Columns.id == id)
                .deleteAll(db)
        }

        await updateMemoriesCount()
    }

    /// Deletes all memories from the database
    nonisolated func clearAll() async {
        guard let dbQueue = dbQueue else { return }

        do {
            try await dbQueue.write { db in
                try Memory.deleteAll(db)
            }
            await updateMemoriesCount()
        } catch {
            log.error("[MemoryManager] clearAll failed: \(error)")
        }
    }

    // MARK: - Private Helpers

    @MainActor
    private func updateMemoriesCount() async {
        guard let dbQueue = dbQueue else { return }

        do {
            let count = try await dbQueue.read { db in
                try Memory.fetchCount(db)
            }
            self.memoriesCount = count
        } catch {
            log.error("[MemoryManager] count failed: \(error)")
        }
    }
}
