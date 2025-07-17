//
//  TypeaheadHistoryManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 6/18/25.
//

import Foundation
import GRDB
import AppKit
import Defaults

// MARK: - Entry Models

struct PasteboardEntry: Codable, Identifiable, Sendable {
    let id: Int64?
    let text: String
    let applicationName: String
    let applicationTitle: String
    let timestamp: Date
    
    init(id: Int64? = nil, text: String, applicationName: String, applicationTitle: String, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.applicationName = applicationName
        self.applicationTitle = applicationTitle
        self.timestamp = timestamp
    }
}

struct HighlightedTextEntry: Codable, Identifiable, Sendable {
    let id: Int64?
    let text: String
    let applicationName: String
    let applicationTitle: String
    let method: String
    let timestamp: Date
    
    init(id: Int64? = nil, text: String, applicationName: String, applicationTitle: String, method: String, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.applicationName = applicationName
        self.applicationTitle = applicationTitle
        self.method = method
        self.timestamp = timestamp
    }
}

struct ContentEntry: Codable, Identifiable, Sendable {
    let id: Int64?
    let content: String
    let applicationName: String
    let applicationTitle: String
    let method: String
    let elapsedTime: Double?
    let timestamp: Date
    
    init(id: Int64? = nil, content: String, applicationName: String, applicationTitle: String, method: String, elapsedTime: Double? = nil, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.applicationName = applicationName
        self.applicationTitle = applicationTitle
        self.method = method
        self.elapsedTime = elapsedTime
        self.timestamp = timestamp
    }
}

struct TypedInputEntry: Codable, Identifiable, Sendable {
    let id: Int64?
    let applicationName: String
    let applicationTitle: String?
    let screenContent: String
    let currentText: String
    let precedingInputText: String
    let followingInputText: String
    let preceedingWindowText: String
    let followingWindowText: String
    let changeText: String?
    let changeType: String?
    let timestamp: Date
    
    init(id: Int64? = nil, applicationName: String, applicationTitle: String?, screenContent: String, currentText: String, precedingInputText: String, followingInputText: String, preceedingWindowText: String, followingWindowText: String, changeText: String?, changeType: String?, timestamp: Date = Date()) {
        self.id = id
        self.applicationName = applicationName
        self.applicationTitle = applicationTitle
        self.screenContent = screenContent
        self.currentText = currentText
        self.precedingInputText = precedingInputText
        self.followingInputText = followingInputText
        self.preceedingWindowText = preceedingWindowText
        self.followingWindowText = followingWindowText
        self.changeText = changeText
        self.changeType = changeType
        self.timestamp = timestamp
    }
}

// MARK: - GRDB Extensions

extension PasteboardEntry: FetchableRecord, PersistableRecord {
    static let databaseTableName = "pasteboard_history"
    
    enum Columns: String, ColumnExpression {
        case id, text, applicationName, applicationTitle, timestamp
    }
    
    init(row: Row) throws {
        id = row[Columns.id]
        text = row[Columns.text]
        applicationName = row[Columns.applicationName]
        applicationTitle = row[Columns.applicationTitle]
        timestamp = row[Columns.timestamp]
    }
    
    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.text] = text
        container[Columns.applicationName] = applicationName
        container[Columns.applicationTitle] = applicationTitle
        container[Columns.timestamp] = timestamp
    }
}

extension HighlightedTextEntry: FetchableRecord, PersistableRecord {
    static let databaseTableName = "highlighted_text_history"
    
    enum Columns: String, ColumnExpression {
        case id, text, applicationName, applicationTitle, method, timestamp
    }
    
    init(row: Row) throws {
        id = row[Columns.id]
        text = row[Columns.text]
        applicationName = row[Columns.applicationName]
        applicationTitle = row[Columns.applicationTitle]
        method = row[Columns.method]
        timestamp = row[Columns.timestamp]
    }
    
    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.text] = text
        container[Columns.applicationName] = applicationName
        container[Columns.applicationTitle] = applicationTitle
        container[Columns.method] = method
        container[Columns.timestamp] = timestamp
    }
}

extension ContentEntry: FetchableRecord, PersistableRecord {
    static let databaseTableName = "content_history"
    
    enum Columns: String, ColumnExpression {
        case id, content, applicationName, applicationTitle, method, elapsedTime, timestamp
    }
    
    init(row: Row) throws {
        id = row[Columns.id]
        content = row[Columns.content]
        applicationName = row[Columns.applicationName]
        applicationTitle = row[Columns.applicationTitle]
        method = row[Columns.method]
        elapsedTime = row[Columns.elapsedTime]
        timestamp = row[Columns.timestamp]
    }
    
    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.content] = content
        container[Columns.applicationName] = applicationName
        container[Columns.applicationTitle] = applicationTitle
        container[Columns.method] = method
        container[Columns.elapsedTime] = elapsedTime
        container[Columns.timestamp] = timestamp
    }
}

extension TypedInputEntry: FetchableRecord, PersistableRecord {
    static let databaseTableName = "typed_input_history"
    
    enum Columns: String, ColumnExpression {
        case id, applicationName, applicationTitle, screenContent, currentText, precedingInputText, followingInputText, preceedingWindowText, followingWindowText, changeText, changeType, timestamp
    }
    
    init(row: Row) throws {
        id = row[Columns.id]
        applicationName = row[Columns.applicationName]
        applicationTitle = row[Columns.applicationTitle]
        screenContent = row[Columns.screenContent]
        currentText = row[Columns.currentText]
        precedingInputText = row[Columns.precedingInputText]
        followingInputText = row[Columns.followingInputText]
        preceedingWindowText = row[Columns.preceedingWindowText]
        followingWindowText = row[Columns.followingWindowText]
        changeText = row[Columns.changeText]
        changeType = row[Columns.changeType]
        timestamp = row[Columns.timestamp]
    }
    
    func encode(to container: inout PersistenceContainer) throws {
        container[Columns.id] = id
        container[Columns.applicationName] = applicationName
        container[Columns.applicationTitle] = applicationTitle
        container[Columns.screenContent] = screenContent
        container[Columns.currentText] = currentText
        container[Columns.precedingInputText] = precedingInputText
        container[Columns.followingInputText] = followingInputText
        container[Columns.preceedingWindowText] = preceedingWindowText
        container[Columns.followingWindowText] = followingWindowText
        container[Columns.changeText] = changeText
        container[Columns.changeType] = changeType
        container[Columns.timestamp] = timestamp
    }
}

// MARK: - HistoryManager


final class TypeaheadHistoryManager: ObservableObject {
    @MainActor
    static let shared = TypeaheadHistoryManager()

    private var dbQueue: DatabaseQueue?
    private let dbFile: String = "typeahead_history.sqlite"
    
    private var dbPath: String? {
        let fileManager = FileManager.default
        
        guard let applicationSupportURL = fileManager
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first else {
            print("Could not find Application Support directory")
            return nil
        }
        
        let onitURL = applicationSupportURL.appendingPathComponent("Onit")
        try? fileManager.createDirectory(at: onitURL, withIntermediateDirectories: true)
        
        return onitURL.appendingPathComponent(dbFile).path
    }

//    lazy var pasteboard = PasteboardHistoryManager(manager: self)
//    lazy var highlightedText = HighlightedTextHistoryManager(manager: self)
//    lazy var content = ContentHistoryManager(manager: self)
////    lazy var typedPhrase = TypedPhraseHistoryManager(manager: self)
//    lazy var typedWord = TypedWordHistoryManager(manager: self)

    private init() {
        setupDatabase()
    }

    // MARK: - Database Setup
    
    private func setupDatabase() {
        guard let dbPath = dbPath else { return }
        
        do {
            dbQueue = try DatabaseQueue(path: dbPath)
            
            try dbQueue?.write { db in
                try createTables(in: db)
            }
            
            print("TypeaheadHistoryManager: Database initialized successfully at: \(dbPath)")
        } catch {
            print("TypeaheadHistoryManager: Failed to setup database: \(error)")
        }
    }
    
    private func createTables(in db: Database) throws {
        // Create pasteboard_history table
        try db.create(table: PasteboardEntry.databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("text", .text).notNull()
            t.column("applicationName", .text).notNull()
            t.column("applicationTitle", .text).notNull()
            t.column("timestamp", .datetime).notNull()
        }
        
        // Create highlighted_text_history table
        try db.create(table: HighlightedTextEntry.databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("text", .text).notNull()
            t.column("applicationName", .text).notNull()
            t.column("applicationTitle", .text).notNull()
            t.column("method", .text).notNull()
            t.column("timestamp", .datetime).notNull()
        }
        
        // Create content_history table
        try db.create(table: ContentEntry.databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("content", .text).notNull()
            t.column("applicationName", .text).notNull()
            t.column("applicationTitle", .text).notNull()
            t.column("method", .text).notNull()
            t.column("elapsedTime", .double)
            t.column("timestamp", .datetime).notNull()
        }
        
        // Create typed_input_history table (unified for both phrase and word)
        try db.create(table: TypedInputEntry.databaseTableName, ifNotExists: true) { t in
            t.autoIncrementedPrimaryKey("id")
            t.column("applicationName", .text).notNull()
            t.column("applicationTitle", .text)
            t.column("screenContent", .text).notNull()
            t.column("currentText", .text).notNull()
            t.column("precedingInputText", .text).notNull()
            t.column("followingInputText", .text).notNull()
            t.column("preceedingWindowText", .text).notNull()
            t.column("followingWindowText", .text).notNull()
            t.column("changeText", .text)
            t.column("changeType", .text)
            t.column("timestamp", .datetime).notNull()
        }
        
        print("TypeaheadHistoryManager: All tables created successfully")
    }
    
    // MARK: - TypedInputEntry
    
    private func saveTypedEntry(_ entry: TypedInputEntry) async {
        guard let dbQueue = dbQueue else { return }
        do {
            try await dbQueue.write { db in
                try entry.insert(db)
            }
        } catch {
            log.error("Failed to save sample: \(error)")
        }
    }
    
    
    
    func addTypedPhrase(applicationName: String,
                        applicationTitle: String?,
                        screenContent: String,
                        currentText: String,
                        precedingInputText: String,
                        followingInputText: String,
                        preceedingWindowText: String,
                        followingWindowText: String,
                        changeText: String?,
                        changeType: String?,
                        timestamp: Date = Date()) async {
        guard Defaults[.collectTypeaheadTestCases] else { return }
        print("historyManager - addTypedPhrase | applicationName: \(applicationName) applicationTitle: \(applicationTitle ?? "nil") screenContent: \(screenContent.prefix(20)) currentText: \(currentText.prefix(20)) precedingInputText: \(precedingInputText.prefix(20)) followingInputText: \(followingInputText.prefix(20)) preceedingWindowText: \(preceedingWindowText.prefix(20)) followingWindowText: \(followingWindowText.prefix(20)) changeText: \(changeText?.prefix(20) ?? "nil") changeType: \(changeType ?? "nil") timestamp: \(timestamp)")
        let entry = TypedInputEntry(
            applicationName: applicationName,
            applicationTitle: applicationTitle,
            screenContent: screenContent,
            currentText: currentText,
            precedingInputText: precedingInputText,
            followingInputText: followingInputText,
            preceedingWindowText: preceedingWindowText,
            followingWindowText: followingWindowText,
            changeText: changeText,
            changeType: changeType,
            timestamp: timestamp)
        await saveTypedEntry(entry)
    }
    
    // MARK: - Content
    
    private func saveContentEntry(_ entry: ContentEntry) async {
        guard let dbQueue = dbQueue else { return }
        do {
            try await dbQueue.write { db in
                try entry.insert(db)
            }
        } catch {
            log.error("Failed to save sample: \(error)")
        }
    }
    
    func addContent(content: String, 
                    applicationName: String, 
                    applicationTitle: String, 
                    method: String, 
                    elapsedTime: Double? = nil, 
                    timestamp: Date = Date()) async {
        guard Defaults[.collectTypeaheadTestCases] else { return }
        print("historyManager - addContent | content: \(content.prefix(20)) applicationName: \(applicationName) applicationTitle: \(applicationTitle) method: \(method) elapsedTime: \(elapsedTime ?? -1) timestamp: \(timestamp)")
        let entry = ContentEntry(
            content: content, 
            applicationName: applicationName, 
            applicationTitle: applicationTitle, 
            method: method, 
            elapsedTime: elapsedTime, 
            timestamp: timestamp)
        await saveContentEntry(entry)
    }
}

