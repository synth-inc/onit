//
//  TypeaheadHistoryManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 6/18/25.
//

import Foundation
import SQLite3
import SwiftData
import AppKit
import Defaults

// MARK: - Entry Models

struct PasteboardEntry {
    let id: Int64
    let text: String
    let applicationName: String
    let applicationTitle: String
    let timestamp: Date
}

struct HighlightedTextEntry {
    let id: Int64
    let text: String
    let applicationName: String
    let applicationTitle: String
    let method: String
    let timestamp: Date
}

struct ContentEntry {
    let id: Int64
    let content: String
    let applicationName: String
    let applicationTitle: String
    let method: String
    let timestamp: Date
}

struct TypedInputEntry {
    let id: Int64
    let applicationName: String
    let applicationTitle: String?
    let screenContent: String
    let currentText: String
    let precedingText: String
    let followingText: String
    let aiCompletion: String?
    let similarityScore: Double?
    let timestamp: Date
}

// MARK: - HistoryManager

final class TypeaheadHistoryManager: ObservableObject, @unchecked Sendable {
    @MainActor
    static let shared = TypeaheadHistoryManager()

    private let dbURL: URL
    private var db: OpaquePointer?
    internal let queue = DispatchQueue(label: "com.onit.historyManager", qos: .background)

    lazy var pasteboard = PasteboardHistoryManager(manager: self)
    lazy var highlightedText = HighlightedTextHistoryManager(manager: self)
    lazy var content = ContentHistoryManager(manager: self)
    lazy var typedInput = TypedInputHistoryManager(manager: self)

    private init() {
        // Store DB in Application Support
        let fm = FileManager.default
        let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("Onit", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        dbURL = dir.appendingPathComponent("history.sqlite3")

        openDatabase()
        createTables()
    }

    deinit {
        sqlite3_close(db)
    }

    private func openDatabase() {
        if sqlite3_open(dbURL.path, &db) != SQLITE_OK {
            print("Failed to open SQLite database at \(dbURL.path)")
        }
    }

    private func createTables() {
        let createPasteboard = """
        CREATE TABLE IF NOT EXISTS pasteboard_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            app TEXT,
            window TEXT,
            timestamp REAL NOT NULL
        );
        """
        let createHighlighted = """
        CREATE TABLE IF NOT EXISTS highlighted_text_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            text TEXT NOT NULL,
            app TEXT NOT NULL,
            window TEXT,
            method TEXT,
            timestamp REAL NOT NULL
        );
        """
        let createContent = """
        CREATE TABLE IF NOT EXISTS content_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            content TEXT NOT NULL,
            app TEXT NOT NULL,
            window TEXT,
            method TEXT,
            timestamp REAL NOT NULL
        );
        """
        let createTypedInput = """
        CREATE TABLE IF NOT EXISTS typed_input_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            applicationName TEXT NOT NULL,
            applicationTitle TEXT,
            screenContent TEXT,
            currentText TEXT,
            precedingText TEXT,
            followingText TEXT,
            aiCompletion TEXT,
            similarityScore REAL,
            timestamp REAL NOT NULL
        );
        """
        queue.sync {
            _ = execute(createPasteboard)
            _ = execute(createHighlighted)
            _ = execute(createContent)
            _ = execute(createTypedInput)
        }
    }

    func execute(_ sql: String, args: [Any?] = []) -> Bool {
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            print("SQLite prepare error: \(String(cString: sqlite3_errmsg(db)))")
            return false
        }
        defer { sqlite3_finalize(stmt) }
        for (i, arg) in args.enumerated() {
            let idx = Int32(i+1)
            if let str = arg as? String {
                sqlite3_bind_text(stmt, idx, str, -1, nil)
            } else if let d = arg as? Double {
                sqlite3_bind_double(stmt, idx, d)
            } else if let i = arg as? Int {
                sqlite3_bind_int(stmt, idx, Int32(i))
            } else if let i64 = arg as? Int64 {
                sqlite3_bind_int64(stmt, idx, i64)
            } else if arg == nil {
                sqlite3_bind_null(stmt, idx)
            }
        }
        if sqlite3_step(stmt) != SQLITE_DONE {
            print("SQLite step error: \(String(cString: sqlite3_errmsg(db)))")
            return false
        }
        return true
    }

    func query(_ sql: String, args: [Any?] = []) -> [[String: Any?]] {
        var stmt: OpaquePointer?
        var rows: [[String: Any?]] = []
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else {
            print("SQLite prepare error: \(String(cString: sqlite3_errmsg(db)))")
            return rows
        }
        defer { sqlite3_finalize(stmt) }
        for (i, arg) in args.enumerated() {
            let idx = Int32(i+1)
            if let str = arg as? String {
                sqlite3_bind_text(stmt, idx, str, -1, nil)
            } else if let d = arg as? Double {
                sqlite3_bind_double(stmt, idx, d)
            } else if let i = arg as? Int {
                sqlite3_bind_int(stmt, idx, Int32(i))
            } else if let i64 = arg as? Int64 {
                sqlite3_bind_int64(stmt, idx, i64)
            } else if arg == nil {
                sqlite3_bind_null(stmt, idx)
            }
        }
        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any?] = [:]
            for i in 0..<sqlite3_column_count(stmt) {
                let name = String(cString: sqlite3_column_name(stmt, i))
                let type = sqlite3_column_type(stmt, i)
                switch type {
                case SQLITE_INTEGER:
                    row[name] = sqlite3_column_int64(stmt, i)
                case SQLITE_FLOAT:
                    row[name] = sqlite3_column_double(stmt, i)
                case SQLITE_TEXT:
                    row[name] = String(cString: sqlite3_column_text(stmt, i))
                case SQLITE_NULL:
                    row[name] = nil
                default:
                    row[name] = nil
                }
            }
            rows.append(row)
        }
        return rows
    }
}

// MARK: - Submanagers

final class PasteboardHistoryManager {
    private unowned let manager: TypeaheadHistoryManager
    init(manager: TypeaheadHistoryManager) { self.manager = manager }

    func add(text: String, applicationName: String, applicationTitle: String, timestamp: Date = Date()) {
        guard Defaults[.collectTypeaheadTestCases] else { return }
        print("historyManager - PasteboardHistoryManager.add | text: \(text.prefix(40)) applicationName: \(applicationName) applicationTitle: \(applicationTitle) timestamp: \(timestamp)")
        let sql = "INSERT INTO pasteboard_history (text, app, window, timestamp) VALUES (?, ?, ?, ?)"
        manager.queue.async {
            _ = self.manager.execute(sql, args: [text, applicationName, applicationTitle, timestamp.timeIntervalSince1970])
        }
    }

    func fetchAll() -> [PasteboardEntry] {
        let sql = "SELECT * FROM pasteboard_history ORDER BY timestamp DESC"
        var result: [PasteboardEntry] = []
        manager.queue.sync {
            let rows = manager.query(sql)
            for row in rows {
                if let id = row["id"] as? Int64,
                   let text = row["text"] as? String,
                   let ts = row["timestamp"] as? Double {
                    let app = row["app"] as? String ?? ""
                    let window = row["window"] as? String ?? ""
                    result.append(PasteboardEntry(id: id, text: text, applicationName: app, applicationTitle: window, timestamp: Date(timeIntervalSince1970: ts)))
                }
            }
        }
        return result
    }
}

final class HighlightedTextHistoryManager {
    private unowned let manager: TypeaheadHistoryManager
    init(manager: TypeaheadHistoryManager) { self.manager = manager }

    func add(text: String, applicationName: String, applicationTitle: String, method: String, timestamp: Date = Date()) {
        guard Defaults[.collectTypeaheadTestCases] else { return }
        print("historyManager - HighlightedTextHistoryManager.add | text: \(text.prefix(40)) applicationName: \(applicationName) applicationTitle: \(applicationTitle) method: \(method) timestamp: \(timestamp)")
        let sql = "INSERT INTO highlighted_text_history (text, app, window, method, timestamp) VALUES (?, ?, ?, ?, ?)"
        manager.queue.async {
            _ = self.manager.execute(sql, args: [text, applicationName, applicationTitle, method, timestamp.timeIntervalSince1970])
        }
    }

    func fetchAll() -> [HighlightedTextEntry] {
        let sql = "SELECT * FROM highlighted_text_history ORDER BY timestamp DESC"
        var result: [HighlightedTextEntry] = []
        manager.queue.sync {
            let rows = manager.query(sql)
            for row in rows {
                if let id = row["id"] as? Int64,
                   let text = row["text"] as? String,
                   let app = row["app"] as? String,
                   let ts = row["timestamp"] as? Double {
                    let window = row["window"] as? String ?? ""
                    let method = row["method"] as? String ?? ""
                    result.append(HighlightedTextEntry(id: id, text: text, applicationName: app, applicationTitle: window, method: method, timestamp: Date(timeIntervalSince1970: ts)))
                }
            }
        }
        return result
    }
}

final class ContentHistoryManager {
    private unowned let manager: TypeaheadHistoryManager
    init(manager: TypeaheadHistoryManager) { self.manager = manager }

    func add(content: String, applicationName: String, applicationTitle: String, method: String, timestamp: Date = Date()) {
        guard Defaults[.collectTypeaheadTestCases] else { return }
        print("historyManager - ContentHistoryManager.add | content: \(content.prefix(40)) applicationName: \(applicationName) applicationTitle: \(applicationTitle) method: \(method) timestamp: \(timestamp)")
        let sql = "INSERT INTO content_history (content, app, window, method, timestamp) VALUES (?, ?, ?, ?, ?)"
        manager.queue.async {
            _ = self.manager.execute(sql, args: [content, applicationName, applicationTitle, method, timestamp.timeIntervalSince1970])
        }
    }

    func fetchAll() -> [ContentEntry] {
        let sql = "SELECT * FROM content_history ORDER BY timestamp DESC"
        var result: [ContentEntry] = []
        manager.queue.sync {
            let rows = manager.query(sql)
            for row in rows {
                if let id = row["id"] as? Int64,
                   let content = row["content"] as? String,
                   let app = row["app"] as? String,
                   let ts = row["timestamp"] as? Double {
                    let window = row["window"] as? String ?? ""
                    let method = row["method"] as? String ?? ""
                    result.append(ContentEntry(id: id, content: content, applicationName: app, applicationTitle: window, method: method, timestamp: Date(timeIntervalSince1970: ts)))
                }
            }
        }
        return result
    }
}

final class TypedInputHistoryManager {
    private unowned let manager: TypeaheadHistoryManager
    init(manager: TypeaheadHistoryManager) { self.manager = manager }

    func add(applicationName: String, applicationTitle: String?, screenContent: String, currentText: String, precedingText: String, followingText: String, aiCompletion: String?, similarityScore: Double?, timestamp: Date = Date()) {
        guard Defaults[.collectTypeaheadTestCases] else { return }
        print("historyManager - TypedInputHistoryManager.add | applicationName: \(applicationName) applicationTitle: \(applicationTitle ?? "nil") screenContent: \(screenContent.prefix(20)) currentText: \(currentText.prefix(20)) precedingText: \(precedingText.prefix(20)) followingText: \(followingText.prefix(20)) aiCompletion: \(aiCompletion ?? "nil") similarityScore: \(similarityScore?.description ?? "nil") timestamp: \(timestamp)")
        let sql = "INSERT INTO typed_input_history (applicationName, applicationTitle, screenContent, currentText, precedingText, followingText, aiCompletion, similarityScore, timestamp) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)"
        manager.queue.async {
            _ = self.manager.execute(sql, args: [applicationName, applicationTitle, screenContent, currentText, precedingText, followingText, aiCompletion, similarityScore, timestamp.timeIntervalSince1970])
        }
    }

    func fetchAll() -> [TypedInputEntry] {
        let sql = "SELECT * FROM typed_input_history ORDER BY timestamp DESC"
        var result: [TypedInputEntry] = []
        manager.queue.sync {
            let rows = manager.query(sql)
            for row in rows {
                if let id = row["id"] as? Int64,
                   let applicationName = row["applicationName"] as? String,
                   let ts = row["timestamp"] as? Double {
                    let applicationTitle = row["applicationTitle"] as? String
                    let screenContent = row["screenContent"] as? String ?? ""
                    let currentText = row["currentText"] as? String ?? ""
                    let precedingText = row["precedingText"] as? String ?? ""
                    let followingText = row["followingText"] as? String ?? ""
                    let aiCompletion = row["aiCompletion"] as? String
                    let similarityScore = row["similarityScore"] as? Double
                    result.append(TypedInputEntry(id: id, applicationName: applicationName, applicationTitle: applicationTitle, screenContent: screenContent, currentText: currentText, precedingText: precedingText, followingText: followingText, aiCompletion: aiCompletion, similarityScore: similarityScore, timestamp: Date(timeIntervalSince1970: ts)))
                }
            }
        }
        return result
    }
}
