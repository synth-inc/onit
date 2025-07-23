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
    let addedText: String?
    let deletedText: String?
    let changeType: String?
    let keystrokes: String? // Store as JSON string
    let confidence: Double? // Confidence score from TextChange calculation
    let confidenceVersion: Double? // Version of the confidence calculation algorithm
    let couldntFindInitialText: Bool
    let timestamp: Date
    
    init(id: Int64? = nil, applicationName: String, applicationTitle: String?, screenContent: String, currentText: String, precedingInputText: String, followingInputText: String, preceedingWindowText: String, followingWindowText: String, addedText: String?, deletedText: String?, changeType: String?, keystrokes: [String]? = nil, confidence: Double? = nil, confidenceVersion: Double? = nil, couldntFindInitialText: Bool = false, timestamp: Date = Date()) {
        self.id = id
        self.applicationName = applicationName
        self.applicationTitle = applicationTitle
        self.screenContent = screenContent
        self.currentText = currentText
        self.precedingInputText = precedingInputText
        self.followingInputText = followingInputText
        self.preceedingWindowText = preceedingWindowText
        self.followingWindowText = followingWindowText
        self.addedText = addedText
        self.deletedText = deletedText
        self.changeType = changeType
        // Convert keystrokes array to JSON string for storage
        if let keystrokes = keystrokes, !keystrokes.isEmpty {
            self.keystrokes = try? String(data: JSONEncoder().encode(keystrokes), encoding: .utf8)
        } else {
            self.keystrokes = nil
        }
        self.confidence = confidence
        self.confidenceVersion = confidenceVersion
        self.couldntFindInitialText = couldntFindInitialText
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
        case id, applicationName, applicationTitle, screenContent, currentText, precedingInputText, followingInputText, preceedingWindowText, followingWindowText, addedText, deletedText, changeType, keystrokes, confidence, confidenceVersion, couldntFindInitialText, timestamp
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
        addedText = row[Columns.addedText]
        deletedText = row[Columns.deletedText]
        changeType = row[Columns.changeType]
        keystrokes = row[Columns.keystrokes]
        confidence = row[Columns.confidence]
        confidenceVersion = row[Columns.confidenceVersion]
        couldntFindInitialText = row[Columns.couldntFindInitialText]
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
        container[Columns.addedText] = addedText
        container[Columns.deletedText] = deletedText
        container[Columns.changeType] = changeType
        container[Columns.keystrokes] = keystrokes
        container[Columns.confidence] = confidence
        container[Columns.confidenceVersion] = confidenceVersion
        container[Columns.couldntFindInitialText] = couldntFindInitialText
        container[Columns.timestamp] = timestamp
    }
}

// MARK: - TypedInputEntry Extensions

extension TypedInputEntry {
    /// Parses the keystrokes JSON string back to an array
    var keystrokesArray: [String] {
        guard let keystrokesData = keystrokes?.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: keystrokesData) else {
            return []
        }
        return array
    }
    
    /// Creates a trimmed version of text for display, showing context around the edit point
    func trimTextForDisplay(_ text: String, changeIndex: Int?, maxLength: Int = 50) -> String {
        guard text.count > maxLength else { return text }
        
        let changeIdx = changeIndex ?? text.count / 2
        let halfLength = maxLength / 2
        
        let startIndex = max(0, changeIdx - halfLength)
        let endIndex = min(text.count, changeIdx + halfLength)
        
        let trimmedText = String(text[text.index(text.startIndex, offsetBy: startIndex)..<text.index(text.startIndex, offsetBy: endIndex)])
        
        let prefix = startIndex > 0 ? "..." : ""
        let suffix = endIndex < text.count ? "..." : ""
        
        return prefix + trimmedText + suffix
    }
    
    /// Gets the estimated change index for trimming purposes
    var estimatedChangeIndex: Int? {
        if let addedText = addedText, !addedText.isEmpty {
            // For additions, look for where the added text appears in currentText
            if let range = currentText.range(of: addedText) {
                return currentText.distance(from: currentText.startIndex, to: range.lowerBound)
            }
        }
        
        if let deletedText = deletedText, !deletedText.isEmpty {
            // For deletions, estimate based on preceding text length
            return precedingInputText.count
        }
        
        return nil
    }
    
    /// Creates display-friendly text before and after for the table
    var displayTextBefore: String {
        let beforeText = precedingInputText + (deletedText ?? "") + followingInputText
        return trimTextForDisplay(beforeText, changeIndex: estimatedChangeIndex)
    }
    
    var displayTextAfter: String {
        return trimTextForDisplay(currentText, changeIndex: estimatedChangeIndex)
    }
}

// MARK: - HistoryManager


final class TypeaheadHistoryManager: ObservableObject, @unchecked Sendable {
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
//        Task {
//            await TypeaheadHistoryManager.shared.migrateOutdatedConfidenceScores()
//        }
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
            t.column("addedText", .text)
            t.column("deletedText", .text)
            t.column("changeType", .text)
            t.column("keystrokes", .text) // JSON string
            t.column("confidence", .double)
            t.column("confidenceVersion", .double)
            t.column("couldntFindInitialText", .boolean).notNull().defaults(to: false)
            t.column("timestamp", .datetime).notNull()
        }
        
        print("TypeaheadHistoryManager: All tables created successfully")
    }
    
    // MARK: - TypedInputEntry
    
    nonisolated private func saveTypedEntry(_ entry: TypedInputEntry) async {
        guard let dbQueue = dbQueue else { return }
        do {
            try await dbQueue.write { db in
                try entry.insert(db)
            }
        } catch {
            log.error("Failed to save sample: \(error)")
        }
    }
    
    
    
    nonisolated func addTypedPhrase(applicationName: String,
                        applicationTitle: String?,
                        screenContent: String,
                        currentText: String,
                        precedingInputText: String,
                        followingInputText: String,
                        preceedingWindowText: String,
                        followingWindowText: String,
                        addedText: String?,
                        deletedText: String?,
                        changeType: String?,
                        keystrokes: [String] = [],
                        confidence: Double? = nil,
                        confidenceVersion: Double? = nil,
                        couldntFindInitialText: Bool = false,
                        timestamp: Date = Date()) async {
        guard Defaults[.collectTypeaheadTestCases] else { return }
        print("historyManager - addTypedPhrase | applicationName: \(applicationName) applicationTitle: \(applicationTitle ?? "nil") screenContent: \(screenContent.prefix(20)) currentText: \(currentText.prefix(20)) precedingInputText: \(precedingInputText.prefix(20)) followingInputText: \(followingInputText.prefix(20)) preceedingWindowText: \(preceedingWindowText.prefix(20)) followingWindowText: \(followingWindowText.prefix(20)) addedText: \(addedText?.prefix(20) ?? "nil") deletedText: \(deletedText?.prefix(20) ?? "nil") changeType: \(changeType ?? "nil") keystrokes: \(keystrokes) confidence: \(confidence ?? -1) confidenceVersion: \(confidenceVersion ?? -1) couldntFindInitialText: \(couldntFindInitialText) timestamp: \(timestamp)")
        let entry = TypedInputEntry(
            applicationName: applicationName,
            applicationTitle: applicationTitle,
            screenContent: screenContent,
            currentText: currentText,
            precedingInputText: precedingInputText,
            followingInputText: followingInputText,
            preceedingWindowText: preceedingWindowText,
            followingWindowText: followingWindowText,
            addedText: addedText,
            deletedText: deletedText,
            changeType: changeType,
            keystrokes: keystrokes,
            confidence: confidence,
            confidenceVersion: confidenceVersion,
            couldntFindInitialText: couldntFindInitialText,
            timestamp: timestamp)
        await saveTypedEntry(entry)
    }
    
    // MARK: - Content
    
    nonisolated private func saveContentEntry(_ entry: ContentEntry) async {
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
//        print("historyManager - addContent | content: \(content.prefix(20)) applicationName: \(applicationName) applicationTitle: \(applicationTitle) method: \(method) elapsedTime: \(elapsedTime ?? -1) timestamp: \(timestamp)")
        let entry = ContentEntry(
            content: content, 
            applicationName: applicationName, 
            applicationTitle: applicationTitle, 
            method: method, 
            elapsedTime: elapsedTime, 
            timestamp: timestamp)
        await saveContentEntry(entry)
    }
    
    // MARK: - Confidence Version Update
    /// Migrates all outdated confidence scores in the database
//    func migrateOutdatedConfidenceScores() async {
//        guard let dbQueue = dbQueue else { return }
//        do {
//            let outdatedEntries = try await dbQueue.read { db in
//                try TypedInputEntry
//                    .filter(TypedInputEntry.Columns.confidenceVersion == nil || TypedInputEntry.Columns.confidenceVersion < TextChangeHelper.confidenceCalculatorVersion)
//                    .fetchAll(db)
//            }
//            print("TypeaheadHistoryManager: Found \(outdatedEntries.count) entries with outdated confidence scores")
//            for entry in outdatedEntries {
//                // Recalculate confidence using the latest version
//                let keystrokesArray = entry.keystrokesArray
//                let textChange = TextChangeHelper.shared.calculateTextChangeFast(
//                    from: entry.precedingInputText + (entry.deletedText ?? ""),
//                    to: entry.currentText,
//                    keystrokes: keystrokesArray
//                )
//                let newConfidence = textChange?.confidence
//                let newVersion = TextChangeHelper.confidenceCalculatorVersion
//                // Update the record in the database
//                do {
//                    try await dbQueue.write { db in
//                        try db.execute(sql: "UPDATE \(TypedInputEntry.databaseTableName) SET confidence = ?, confidenceVersion = ? WHERE id = ?", arguments: [newConfidence, newVersion, entry.id])
//                    }
//                } catch {
//                    print("Failed to update confidence for entry id \(entry.id ?? -1): \(error)")
//                }
//            }
//            if !outdatedEntries.isEmpty {
//                print("TypeaheadHistoryManager: Successfully migrated \(outdatedEntries.count) confidence scores to version \(TextChangeHelper.confidenceCalculatorVersion)")
//            }
//        } catch {
//            print("TypeaheadHistoryManager: Failed to migrate confidence scores: \(error)")
//        }
//    }

    /// Checks and updates confidence/confidenceVersion for outdated entries
//    nonisolated func updateOutdatedConfidenceScores(entries: [TypedInputEntry]) async {
//        guard let dbQueue = dbQueue else { return }
//        for entry in entries {
//            let needsUpdate = entry.confidenceVersion == nil || (entry.confidenceVersion ?? 0) < TextChangeHelper.confidenceCalculatorVersion
//            if needsUpdate {
//                // Recalculate confidence using the latest version
//                let keystrokesArray = entry.keystrokesArray
//                let textChange = TextChangeHelper.shared.calculateTextChangeFast(
//                    from: entry.precedingInputText + (entry.deletedText ?? ""),
//                    to: entry.currentText,
//                    keystrokes: keystrokesArray
//                )
//                let newConfidence = textChange?.confidence
//                let newVersion = TextChangeHelper.confidenceCalculatorVersion
//                // Update the record in the database
//                do {
//                    try await dbQueue.write { db in
//                        try db.execute(sql: "UPDATE \(TypedInputEntry.databaseTableName) SET confidence = ?, confidenceVersion = ? WHERE id = ?", arguments: [newConfidence, newVersion, entry.id])
//                    }
//                } catch {
//                    print("Failed to update confidence for entry id \(entry.id ?? -1): \(error)")
//                }
//            }
//        }
//    }

    // MARK: - Fetching TypedInputEntry
    
    nonisolated func fetchTypedInputEntries(limit: Int = 100) async -> [TypedInputEntry] {
        guard let dbQueue = dbQueue else { return [] }
        
        do {
            return try await dbQueue.read { db in
                try TypedInputEntry
                    .order(TypedInputEntry.Columns.timestamp.desc)
                    .limit(limit)
                    .fetchAll(db)
            }
        } catch {
            log.error("Failed to fetch typed input entries: \(error)")
            return []
        }
    }
    
    nonisolated func clearAllTypedInputEntries() async {
        guard let dbQueue = dbQueue else { return }
        
        do {
            try await dbQueue.write { db in
                try TypedInputEntry.deleteAll(db)
            }
            print("TypeaheadHistoryManager: All typed input entries cleared")
        } catch {
            log.error("Failed to clear typed input entries: \(error)")
        }
    }
}

