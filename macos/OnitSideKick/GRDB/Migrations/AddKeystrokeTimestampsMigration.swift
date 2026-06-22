//
//  AddKeystrokeTimestampsMigration.swift
//  Onit
//
//  Created by Kévin Naudin on 09/16/2025.
//

import Foundation
import GRDB

/// Migration to add keystrokeTimestamps column to typed_input_history table
final class AddKeystrokeTimestampsMigration: GRDBMigration {
    
    var version: Int { return 1 }
    
    var description: String {
        return "Add keystrokeTimestamps column to typed_input_history table"
    }
    
    func migrate(_ db: Database) throws {
        let tableExists = try db.tableExists("typed_input_history")
        let columnExists = try db.columns(in: "typed_input_history").contains { $0.name == "keystrokeTimestamps" }
        
        if tableExists && !columnExists {
            try db.alter(table: "typed_input_history") { t in
                t.add(column: "keystrokeTimestamps", .text)
            }
        }
    }
}
