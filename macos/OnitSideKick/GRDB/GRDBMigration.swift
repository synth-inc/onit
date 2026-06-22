//
//  GRDBMigration.swift
//  Onit
//
//  Created by Kévin Naudin on 09/16/2025.
//

import Foundation
import GRDB

// MARK: - GRDBMigration Protocol

protocol GRDBMigration {
    var version: Int { get }
    var description: String { get }
    
    func migrate(_ db: Database) throws
}

// MARK: - GRDBMigration Error

enum GRDBMigrationError: Error {
    case migrationNotFound(version: Int)
    case migrationFailed(version: Int, error: Error)
    case rollbackFailed(version: Int, error: Error)
    case invalidVersion(current: Int, target: Int)
    
    var localizedDescription: String {
        switch self {
        case .migrationNotFound(let version):
            return "Migration version \(version) not found"
        case .migrationFailed(let version, let error):
            return "Migration version \(version) failed: \(error.localizedDescription)"
        case .rollbackFailed(let version, let error):
            return "Rollback version \(version) failed: \(error.localizedDescription)"
        case .invalidVersion(let current, let target):
            return "Invalid migration path from version \(current) to \(target)"
        }
    }
}

// MARK: - GRDBMigration Result

enum GRDBMigrationResult {
    case success(fromVersion: Int, toVersion: Int)
    case noMigrationNeeded(currentVersion: Int)
    case failure(error: GRDBMigrationError)
    
    var isSuccess: Bool {
        switch self {
        case .success, .noMigrationNeeded:
            return true
        case .failure:
            return false
        }
    }
}
