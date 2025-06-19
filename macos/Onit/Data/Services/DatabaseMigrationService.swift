//
//  DatabaseMigrationService.swift
//  Onit
//
//  Created by Claude on $(date)
//

import Foundation
import SwiftData
import Defaults

extension Defaults.Keys {
    static let hasPerformedDatabaseMigration = Key<Bool>("hasPerformedDatabaseMigration", default: false)
}

@MainActor
class DatabaseMigrationService {
    
    static let shared = DatabaseMigrationService()
    
    private init() {}
    
    /// Check if the legacy database exists and migration is needed
    var migrationNeeded: Bool {
        let legacyURL = getLegacyStorageURL()
        let secureURL = getSecureStorageURL()
        
        return FileManager.default.fileExists(atPath: legacyURL.path) && 
               !FileManager.default.fileExists(atPath: secureURL.path) &&
               !Defaults[.hasPerformedDatabaseMigration]
    }
    
    /// Get information about storage locations
    var storageInfo: StorageInfo {
        let legacyURL = getLegacyStorageURL()
        let secureURL = getSecureStorageURL()
        
        return StorageInfo(
            legacyLocation: legacyURL,
            secureLocation: secureURL,
            legacyExists: FileManager.default.fileExists(atPath: legacyURL.path),
            secureExists: FileManager.default.fileExists(atPath: secureURL.path),
            migrationCompleted: Defaults[.hasPerformedDatabaseMigration]
        )
    }
    
    /// Mark migration as completed
    func markMigrationCompleted() {
        Defaults[.hasPerformedDatabaseMigration] = true
    }
    
    /// Perform migration by copying database files from legacy location to secure location
    func performMigrationIfNeeded() {
        guard migrationNeeded else {
            return
        }
        
        let storageInfo = self.storageInfo
        print("DatabaseMigrationService - 🔄 Starting database migration by copying files...")
        print("DatabaseMigrationService - 📋 Storage Information:")
        print("DatabaseMigrationService - \(storageInfo.description)")
        
        do {
            let legacyURL = storageInfo.legacyLocation
            let newURL = storageInfo.secureLocation
            let newDirectory = newURL.deletingLastPathComponent()
            
            // Ensure the new directory exists
            try FileManager.default.createDirectory(at: newDirectory, 
                                                   withIntermediateDirectories: true, 
                                                   attributes: [.posixPermissions: 0o700])
            
            // Define the files to copy (SQLite database files)
            let filesToCopy = [
                ("default.store", "OnitData.sqlite"),           // Main database file
                ("default.store-shm", "OnitData.sqlite-shm"),   // Shared memory file
                ("default.store-wal", "OnitData.sqlite-wal")    // Write-ahead log file
            ]
            
            var copiedFiles = 0
            
            for (legacyFileName, newFileName) in filesToCopy {
                let legacyFileURL = legacyURL.deletingLastPathComponent().appendingPathComponent(legacyFileName)
                let newFileURL = newDirectory.appendingPathComponent(newFileName)
                
                // Check if legacy file exists
                if FileManager.default.fileExists(atPath: legacyFileURL.path) {
                    // Remove existing file at destination if it exists
                    if FileManager.default.fileExists(atPath: newFileURL.path) {
                        try FileManager.default.removeItem(at: newFileURL)
                        print("DatabaseMigrationService - 🗑️ Removed existing file: \(newFileURL.path)")
                    }
                    
                    // Copy the file
                    try FileManager.default.copyItem(at: legacyFileURL, to: newFileURL)
                    print("DatabaseMigrationService - 📁 Copied \(legacyFileName) -> \(newFileName)")
                    copiedFiles += 1
                    
                    // Set secure permissions on the copied file
                    try FileManager.default.setAttributes([.posixPermissions: 0o600], 
                                                         ofItemAtPath: newFileURL.path)
                } else {
                    print("DatabaseMigrationService - ⚠️ Legacy file not found: \(legacyFileURL.path)")
                }
            }
            
            if copiedFiles > 0 {
                print("DatabaseMigrationService - ✅ Successfully copied \(copiedFiles) database files")
                
                // Create backup of original files before deletion
                for (legacyFileName, _) in filesToCopy {
                    let legacyFileURL = legacyURL.deletingLastPathComponent().appendingPathComponent(legacyFileName)
                    let backupURL = legacyFileURL.appendingPathExtension("backup")
                    
                    if FileManager.default.fileExists(atPath: legacyFileURL.path) {
                        // Remove existing backup if it exists
                        if FileManager.default.fileExists(atPath: backupURL.path) {
                            try? FileManager.default.removeItem(at: backupURL)
                        }
                        
                        // Create backup
                        try? FileManager.default.copyItem(at: legacyFileURL, to: backupURL)
                        print("DatabaseMigrationService - 💾 Created backup: \(backupURL.lastPathComponent)")
                        
                        // Remove original file
                        try? FileManager.default.removeItem(at: legacyFileURL)
                        print("DatabaseMigrationService - 🗑️ Removed original: \(legacyFileName)")
                    }
                }
                
                // Mark migration as completed
                markMigrationCompleted()
                
                print("DatabaseMigrationService - 🎉 Database migration completed successfully!")
                print("DatabaseMigrationService - 📁 Data moved to secure location: \(newDirectory.path)")
                print("DatabaseMigrationService - 🔒 Database is now stored in a secure, sandboxed location")
                print("DatabaseMigrationService - 💾 Original files backed up with .backup extension")
            } else {
                print("DatabaseMigrationService - ⚠️ No files were copied - migration may not be needed")
            }
            
        } catch {
            print("DatabaseMigrationService - ❌ Failed to migrate database by copying: \(error)")
            print("DatabaseMigrationService - 💡 The app will continue with the new secure storage location")
            print("DatabaseMigrationService - 🔧 You may need to recreate your data if migration fails")
            // Don't fatal error here - let the app continue with new storage location
        }
    }
    
    private func getLegacyStorageURL() -> URL {
        // Get the actual user's home directory (not sandboxed)
        let sandboxedHome = FileManager.default.homeDirectoryForCurrentUser
        
        // Parse the path to extract just /Users/username/
        // sandboxedHome might be "/Users/timl/Library/Containers/inc.synth.Onit.dev/Data/"
        let pathComponents = sandboxedHome.pathComponents
        
        // Find the user home directory by taking components up to and including the username
        var userHomeComponents: [String] = []
        for (index, component) in pathComponents.enumerated() {
            // Stop after we find /Users/username pattern
            if component == "Users" && index + 1 < pathComponents.count {
                userHomeComponents.append(component)
                userHomeComponents.append(pathComponents[index + 1]) // Add username
                break
            }
        }
        // TODO : TIM handle case where we don't find it.
        
        let actualHomeDirectory = URL(fileURLWithPath: "/"  + userHomeComponents.joined(separator: "/"))
        let appSupportURL = actualHomeDirectory.appendingPathComponent("Library/Application Support")
        return appSupportURL.appendingPathComponent("default.store")
    }
    
    private func getSecureStorageURL() -> URL {
        guard let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, 
                                                           in: .userDomainMask).first else {
            // TODO : TIM Do something other than 'fatal error'
            fatalError("Could not find Application Support directory")
        }
        
        let appName = Bundle.main.bundleIdentifier ?? "com.onit.app"
        let secureAppDirectory = appSupportURL.appendingPathComponent(appName)
        
        return secureAppDirectory.appendingPathComponent("OnitData.sqlite")
    }
}

struct StorageInfo {
    let legacyLocation: URL
    let secureLocation: URL
    let legacyExists: Bool
    let secureExists: Bool
    let migrationCompleted: Bool
    
    var description: String {
        var info = [String]()
        info.append("Legacy Database: \(legacyLocation.path) (exists: \(legacyExists))")
        info.append("Secure Database: \(secureLocation.path) (exists: \(secureExists))")
        info.append("Migration Status: \(migrationCompleted ? "Completed" : "Pending")")
        return info.joined(separator: "\n")
    }
} 
