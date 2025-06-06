//
//  DebugManager.swift
//  Onit
//
//  Created by Kévin Naudin on 02/04/2025.
//

import Defaults
import SwiftUI

@MainActor
class DebugManager: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = DebugManager()
    
    // MARK: - Properties
    
    @Published var showDebugWindow = false
    @Default(.enableOCRComparison) var enableOCRComparison
    @Default(.enableAutoOCRComparison) var enableAutoOCRComparison
    @Published var debugText: String = ""
    @Published var ocrComparisonResults: [OCRComparisonResult] = []
    
    var debugPanel: NSPanel? = nil
    
    var hasAutoOCRDelegate: Bool {
        autoOCRDelegate != nil
    }
    
    // MARK: - Private Properties
    
    private var autoOCRDelegate: AutoOCRComparisonDelegate?
    
    // MARK: - Initialization
    
    private init() {
        // Load persisted OCR comparison results
        loadOCRComparisonResults()
        
        // Clean up orphaned screenshot files
        cleanupOldScreenshots()
        
        if enableAutoOCRComparison {
            startAutoOCRComparison()
        }
    }
    
    // MARK: - Functions
    
    func openDebugWindow() {
        let debugPanel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 800),
            styleMask: [.resizable, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false)
        debugPanel.isOpaque = false
        debugPanel.backgroundColor = NSColor.clear
        debugPanel.level = .floating
        debugPanel.titleVisibility = .hidden
        debugPanel.titlebarAppearsTransparent = true
        debugPanel.isMovableByWindowBackground = true
        //debugPanel.delegate = self

        debugPanel.standardWindowButton(.closeButton)?.isHidden = true
        debugPanel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        debugPanel.standardWindowButton(.zoomButton)?.isHidden = true
        debugPanel.isFloatingPanel = true

        let debugPanelContentView = NSHostingView(rootView: DebugView())
        debugPanelContentView.wantsLayer = true
        debugPanelContentView.layer?.cornerRadius = 14
        debugPanelContentView.layer?.cornerCurve = .continuous
        debugPanelContentView.layer?.masksToBounds = true
        debugPanelContentView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        debugPanel.contentView = debugPanelContentView
        debugPanel.contentView?.setFrameOrigin(NSPoint(x: 0, y: 0))

        debugPanel.makeKeyAndOrderFront(nil)
        debugPanel.orderFrontRegardless()
        
        self.debugPanel = debugPanel
    }

    func closeDebugWindow() {
        guard let panel = debugPanel else { return }
        
        panel.orderOut(nil)
        self.debugPanel = nil
    }
    
    func startAutoOCRComparison() {
        guard autoOCRDelegate == nil else {
            print("startAutoOCRComparison: delegate already exists")
            return
        }
        
        let delegate = AutoOCRComparisonDelegate()
        print("startAutoOCRComparison: created new delegate")
        AccessibilityNotificationsManager.shared.addDelegate(delegate)
        print("startAutoOCRComparison: added delegate to notifications manager")
        autoOCRDelegate = delegate
        print("startAutoOCRComparison: stored delegate reference")
        
        if let _ = autoOCRDelegate {
            print("startAutoOCRComparison: delegate successfully stored")
        }
    }
    
    func stopAutoOCRComparison() {
        guard let delegate = autoOCRDelegate else { return }
        
        print("Removing AutoOCRComparisonDelegate from AccessibilityNotificationsManager")
        AccessibilityNotificationsManager.shared.removeDelegate(delegate)
        autoOCRDelegate = nil
        
        if autoOCRDelegate == nil {
            print("AutoOCRComparisonDelegate successfully removed")
        }
    }
    
    func addOCRComparisonResult(_ result: OCRComparisonResult) {
        if let existingIndex = ocrComparisonResults.firstIndex(where: { existing in
            // Same app and title
            existing.appName == result.appName &&
            existing.appTitle == result.appTitle &&
            // Within last 5 minutes
            abs(existing.timestamp.timeIntervalSince(result.timestamp)) < 300 &&
            // Similar match percentage (within 5%)
            abs(existing.matchPercentage - result.matchPercentage) < 5
        }) {
            // Update the existing result if the new one has a lower match percentage
            if result.matchPercentage < ocrComparisonResults[existingIndex].matchPercentage {
                ocrComparisonResults[existingIndex] = result
            }
            // Save after update
            saveOCRComparisonResults()
            return
        }
        
        ocrComparisonResults.append(result)
        
        // Keep only the last 100 results to prevent memory issues
        if ocrComparisonResults.count > 100 {
            ocrComparisonResults.removeFirst(ocrComparisonResults.count - 100)
        }
        
        // Save after adding
        saveOCRComparisonResults()
    }
    
    func removeOCRComparisonResult(_ result: OCRComparisonResult) {
        // Clean up associated files before removing
        result.cleanupFiles()
        ocrComparisonResults.removeAll { $0.id == result.id }
        saveOCRComparisonResults()
    }
    
    func clearOCRComparisonResults() {
        // Clean up all associated files before clearing
        for result in ocrComparisonResults {
            result.cleanupFiles()
        }
        ocrComparisonResults.removeAll()
        saveOCRComparisonResults()
    }
    
    var failedOCRResults: [OCRComparisonResult] {
        ocrComparisonResults.filter { $0.matchPercentage < 70 }
    }
    
    func loadOCRComparisonResults() {
        guard let data = Defaults[.ocrComparisonResults] else { return }
        
        do {
            let loadedResults = try JSONDecoder().decode([OCRComparisonResult].self, from: data)
            // Filter out results with missing files
            ocrComparisonResults = loadedResults.filter { result in
                let screenshotExists = result.screenshotPath == nil || FileManager.default.fileExists(atPath: result.screenshotPath!)
                let debugScreenshotExists = result.debugScreenshotPath == nil || FileManager.default.fileExists(atPath: result.debugScreenshotPath!)
                return screenshotExists && debugScreenshotExists
            }
        } catch {
            print("Failed to load OCR comparison results: \(error)")
            ocrComparisonResults = []
        }
    }
    
    private func saveOCRComparisonResults() {
        do {
            let data = try JSONEncoder().encode(ocrComparisonResults)
            Defaults[.ocrComparisonResults] = data
        } catch {
            print("Failed to save OCR comparison results: \(error)")
        }
    }
    
    func cleanupOldScreenshots() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let ocrFolder = documentsPath.appendingPathComponent("OCRScreenshots")
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: ocrFolder, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        let currentPaths = Set(ocrComparisonResults.compactMap { $0.screenshotPath } + ocrComparisonResults.compactMap { $0.debugScreenshotPath })
        
        // Remove files that are no longer referenced
        for file in files {
            if !currentPaths.contains(file.path) {
                try? FileManager.default.removeItem(at: file)
                print("Cleaned up orphaned screenshot: \(file.lastPathComponent)")
            }
        }
    }
}

// MARK: - Auto OCR Comparison Delegate

@MainActor
private final class AutoOCRComparisonDelegate: AccessibilityNotificationsDelegate {
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        print("AutoOCRDelegate: didActivateWindow called")
        guard DebugManager.shared.enableAutoOCRComparison else {
            print("AutoOCRDelegate: comparison disabled, skipping")
            return
        }
        
        Task {
            print("AutoOCRDelegate: starting OCR comparison for window: \(window.element.title() ?? "unknown")")
            await performOCRComparison(for: window)
        }
    }
    
    private func performOCRComparison(for window: TrackedWindow) async {
        guard let pid = window.element.pid() else { return }
        
        do {
            // Get accessibility text
            let accessibilityResults = await AccessibilityParser.shared.getAllTextInElement(windowElement: window.element)
            let accessibilityText = accessibilityResults["screen"] ?? ""
            
            // Get OCR text
            let appName = window.element.appName() ?? "Unknown"
            let appTitle = window.element.title() ?? appName
            
            // Get OCR observations and screenshot
            let (observations, screenshot) = try await OCRManager.shared.extractTextFromApp(appName)
            let accessibilityWords = accessibilityText.components(separatedBy: .whitespacesAndNewlines)
                .filter { $0.count > 1 }
            var matchedWords = 0
            var totalWords = 0
            // Compare each observation with accessibility text
            var ocrObservations = observations
            for i in 0..<ocrObservations.count {
                let ocrWords = ocrObservations[i].text.components(separatedBy: .whitespacesAndNewlines)
                    .filter { $0.count > 1 }
                let percentageContained = compareOCRWithAutoContext(ocrWords: ocrWords, accessibilityWords: accessibilityWords)
                ocrObservations[i].isFoundInAccessibility = percentageContained >= 80
                ocrObservations[i].percentageMatched = percentageContained

                let newMatchedWords = Int((Double(percentageContained) / 100.0) * Double(ocrWords.count))
                if percentageContained > 0 {
                    print("Here")
                }
                print("New matched words: \(newMatchedWords)")
                matchedWords += newMatchedWords
                totalWords += ocrWords.count
                print("performOCRComparison - Observation '\(ocrObservations[i].text)' found: \(ocrObservations[i].isFoundInAccessibility)")
            }

            // Calculate overall match percentage
            if totalWords > 0 {
                let matchPercentage = Int((Double(matchedWords) / Double(totalWords)) * 100)
                // Create debug image for failed observations
                let failedObservations = ocrObservations.filter { !$0.isFoundInAccessibility }
                print("performOCRComparison - Total observations: \(observations.count), Failed observations: \(failedObservations.count)")
                
                let debugScreenshot = WindowCaptureOCR().createDebugImage(
                    original: screenshot,
                    failedObservations: failedObservations
                )
                print("performOCRComparison - totalWords: \(totalWords) matchedWords: \(matchedWords) matchPercentage: \(matchPercentage)%")
//                print("performOCRComparison - match percentage: \(matchPercentage)%")
                
                await MainActor.run {
                    let result = OCRComparisonResult(
                        appName: appName,
                        appTitle: appTitle,
                        matchPercentage: matchPercentage,
                        accessibilityText: accessibilityText,
                        ocrObservations: ocrObservations,
                        screenshot: screenshot,
                        debugScreenshot: debugScreenshot,
                        appBundleUrl: NSRunningApplication(processIdentifier: pid)?.bundleURL
                    )
                    
                    DebugManager.shared.addOCRComparisonResult(result)
                }
            } else {
                print("Skipping, didn't find any words...")
            }
        } catch {
            print("Failed to perform OCR comparison: \(error)")
        }
    }
    
    private func compareOCRWithAutoContext(ocrWords: [String], accessibilityWords:  [String]) -> Int {
        guard !ocrWords.isEmpty, !accessibilityWords.isEmpty else { return 0 }
        
        let accessibilityWordsSet = Set(accessibilityWords)
        let matchingWords = ocrWords.filter { accessibilityWordsSet.contains($0) }
        let unmatchedWords = ocrWords.filter { !accessibilityWordsSet.contains($0) }
        
        print("compareOCRWithAutoContext - Matched words: \(matchingWords)")
        print("compareOCRWithAutoContext - Unmatched words: \(unmatchedWords)")
        
        let percentage = (Double(matchingWords.count) / Double(ocrWords.count)) * 100.0
        return Int(percentage.rounded())
    }
    
    // Required delegate methods (no-op)
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didChangeWindowTitle window: TrackedWindow) {}
}
