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
         screenshot: NSImage?,
         debugScreenshot: NSImage?,
         debugAccessibilityScreenshot: NSImage?,
         appBundleUrl: URL?) {
        self.appName = appName
        self.appTitle = appTitle
        self.timestamp = Date()
        self.matchPercentage = matchPercentage
        self.accessibilityText = accessibilityText
        self.ocrObservations = ocrObservations
        self.appBundleUrl = appBundleUrl
        self.screenshotPath = Self.saveImageToDisk(screenshot, prefix: "screenshot_\(id.uuidString)")
        self.debugScreenshotPath = Self.saveImageToDisk(debugScreenshot, prefix: "debug_\(id.uuidString)")
        self.debugAccessibilityScreenshotPath = Self.saveImageToDisk(debugAccessibilityScreenshot, prefix: "debug_accessibility_\(id.uuidString)")
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
    
    // MARK: - Disk Storage
    
    private static func saveImageToDisk(_ image: NSImage?, prefix: String) -> String? {
        guard let image = image,
              let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let ocrFolder = documentsPath.appendingPathComponent("OCRScreenshots")
        try? FileManager.default.createDirectory(at: ocrFolder, withIntermediateDirectories: true)
        
        let fileName = "\(prefix)_\(Date().timeIntervalSince1970).png"
        let fileURL = ocrFolder.appendingPathComponent(fileName)

        do {
            try pngData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("Failed to save screenshot to disk: \(error)")
            return nil
        }
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
