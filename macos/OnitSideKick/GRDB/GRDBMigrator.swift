//
//  GRDBMigrator.swift
//  Onit
//
//  Created by Kévin Naudin on 09/16/2025.
//

import Foundation
import GRDB
import OSLog

// MARK: - GRDBMigrator

final class GRDBMigrator {
    
    // MARK: - Properties
    
    private var migrations: [Int: GRDBMigration] = [:]
    private let schemaVersionKey = "schema_version"
    
    var latestVersion: Int {
        return migrations.keys.max() ?? 0
    }
    
    // MARK: - Initialization
    
    init() {
        registerMigrations()
    }
    
    // MARK: - Public Functions
    
    func register(migration: GRDBMigration) {
        migrations[migration.version] = migration
    }
    
    func getCurrentVersion(_ db: Database) throws -> Int {
        do {
            return try Int.fetchOne(db, sql: "PRAGMA user_version") ?? 0
        } catch {
            return 0
        }
    }
    
    @discardableResult
    func migrate(_ db: Database, to targetVersion: Int? = nil) throws -> GRDBMigrationResult {
        let currentVersion = try getCurrentVersion(db)
        let target = targetVersion ?? latestVersion
        
        guard currentVersion != target else {
            return .noMigrationNeeded(currentVersion: currentVersion)
        }
        
        guard target > currentVersion else {
            let error = GRDBMigrationError.invalidVersion(current: currentVersion, target: target)
            
            return .failure(error: error)
        }
        
        do {
            for version in (currentVersion + 1)...target {
                try executeMigration(db, version: version)
            }
            
            try setVersion(db, version: target)
            
            return .success(fromVersion: currentVersion, toVersion: target)
        } catch let error as GRDBMigrationError {
            return .failure(error: error)
        } catch {
            let migrationError = GRDBMigrationError.migrationFailed(version: target, error: error)
            
            return .failure(error: migrationError)
        }
    }
    
    // MARK: - Private Functions
    
    private func registerMigrations() {
        register(migration: AddKeystrokeTimestampsMigration())
    }
    
    private func setVersion(_ db: Database, version: Int) throws {
        try db.execute(sql: "PRAGMA user_version = \(version)")
    }
    
    private func executeMigration(_ db: Database, version: Int) throws {
        guard let migration = migrations[version] else {
            throw GRDBMigrationError.migrationNotFound(version: version)
        }
        
        do {
            try migration.migrate(db)
        } catch {
            throw GRDBMigrationError.migrationFailed(version: version, error: error)
        }
    }
}
