//
//  OCRComparisonResult.swift
//  Onit
//
//  Created by Alex Carmack on 2024.
//

import Foundation
import AppKit

struct OCRComparisonResult: Codable, Identifiable, Hashable {
    let id = UUID()
    let appName: String
    let appTitle: String
    let timestamp: Date
    let matchPercentage: Int
    let accessibilityText: String
    let ocrObservations: [OCRTextObservation]
    let screenshotPath: String?
    let debugScreenshotPath: String?
    let debugAccessibilityScreenshotPath: String?
    let appBundleUrl: URL?
    
    var screenshot: NSImage? {
        guard let path = screenshotPath,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return NSImage(data: data)
    }
    
    var debugScreenshot: NSImage? {
        guard let path = debugScreenshotPath,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return NSImage(data: data)
    }
    
    var debugAccessibilityScreenshot: NSImage? {
        guard let path = debugAccessibilityScreenshotPath,
              let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return nil }
        return NSImage(data: data)
    }
    
    init(appName: String,
         appTitle: String,
         matchPercentage: Int,
         accessibilityText: String,
         ocrObservations: [OCRTextObservation],
         screenshotPath: String?,
         debugScreenshotPath: String?,
         debugAccessibilityScreenshotPath: String?,
         appBundleUrl: URL?) {
        self.appName = appName
        self.appTitle = appTitle
        self.timestamp = Date()
        self.matchPercentage = matchPercentage
        self.accessibilityText = accessibilityText
        self.ocrObservations = ocrObservations
        self.screenshotPath = screenshotPath
        self.debugScreenshotPath = debugScreenshotPath
        self.debugAccessibilityScreenshotPath = debugAccessibilityScreenshotPath
        self.appBundleUrl = appBundleUrl
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: OCRComparisonResult, rhs: OCRComparisonResult) -> Bool {
        lhs.id == rhs.id
    }
    
    enum CodingKeys: String, CodingKey {
        case id, appName, appTitle, timestamp, matchPercentage
        case accessibilityText, ocrObservations, appBundleUrl
        case screenshotPath, debugScreenshotPath, debugAccessibilityScreenshotPath
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(appName, forKey: .appName)
        try container.encode(appTitle, forKey: .appTitle)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(matchPercentage, forKey: .matchPercentage)
        try container.encode(accessibilityText, forKey: .accessibilityText)
        try container.encode(ocrObservations, forKey: .ocrObservations)
        try container.encode(appBundleUrl, forKey: .appBundleUrl)
        try container.encode(screenshotPath, forKey: .screenshotPath)
        try container.encode(debugScreenshotPath, forKey: .debugScreenshotPath)
        try container.encode(debugAccessibilityScreenshotPath, forKey: .debugAccessibilityScreenshotPath)
    }
    
    // Clean up files when result is deleted
    func cleanupFiles() {
        if let path = screenshotPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        if let path = debugScreenshotPath {
            try? FileManager.default.removeItem(atPath: path)
        }
        if let path = debugAccessibilityScreenshotPath {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}
