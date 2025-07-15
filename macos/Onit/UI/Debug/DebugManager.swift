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
    
    private var autoOCRDelegate: WindowChangeDelegate?
    private var currentOCRTask: Task<Void, Never>?
    private var debounceTimer: Timer?
    private let debounceDelay: TimeInterval = 0.5 // 500ms debounce
    
    // MARK: - Initialization
    
    private init() {
        #if DEBUG || BETA
        // Load persisted OCR comparison results
        loadOCRComparisonResults()
        
        // Clean up orphaned screenshot files
        cleanupOldScreenshots()
        
        if enableAutoOCRComparison {
            startAutoOCRComparison()
        }
        #endif
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
        
        let delegate = WindowChangeDelegate { windowInfo in
            self.handleWindowChange(windowInfo)
        }
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
        
        print("Removing WindowChangeDelegate from AccessibilityNotificationsManager")
        AccessibilityNotificationsManager.shared.removeDelegate(delegate)
        autoOCRDelegate = nil
        
        debounceTimer?.invalidate()
        currentOCRTask?.cancel()
        
        if autoOCRDelegate == nil {
            print("WindowChangeDelegate successfully removed")
        }
    }
    
    private func handleWindowChange(_ windowInfo: WindowChangeInfo) {
        print("DebugManager: handleWindowChange called")
        guard enableAutoOCRComparison else {
            print("DebugManager: comparison disabled, skipping")
            return
        }
        
        guard let windowElement = windowInfo.element else {
            print("DebugManager: no window element, skipping")
            return
        }
        
        debounceTimer?.invalidate()
        
        let windowTitle = windowInfo.windowName ?? "unknown"
        print("DebugManager: debouncing OCR comparison for window: \(windowTitle)")
        
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDelay, repeats: false) { _ in
            Task { @MainActor in
                self.currentOCRTask?.cancel()
                self.currentOCRTask = Task {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    print("DebugManager: starting OCR comparison for window: \(windowTitle)")
                    
                    // Check if task was cancelled before starting
                    guard !Task.isCancelled else {
                        print("DebugManager: OCR comparison cancelled before starting")
                        return
                    }
                    
                    await self.performOCRComparison(for: windowElement)
                    
                    // Check if task was cancelled after completion
                    guard !Task.isCancelled else {
                        print("DebugManager: OCR comparison cancelled after completion")
                        return
                    }
                    
                    let endTime = CFAbsoluteTimeGetCurrent()
                    print("DebugManager: OCR comparison completed in \(endTime - startTime) seconds")
                }
            }
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
                // Clean up old files before replacing
                ocrComparisonResults[existingIndex].cleanupFiles()
                ocrComparisonResults[existingIndex] = result
            }
            // Save after update
            saveOCRComparisonResults()
            return
        }
        
        ocrComparisonResults.append(result)
        
        // Keep only the last 500 results to prevent memory issues
        if ocrComparisonResults.count > 500 {
            // Clean up files before removing old results
            let resultsToRemove = ocrComparisonResults.prefix(ocrComparisonResults.count - 500)
            for result in resultsToRemove {
                result.cleanupFiles()
            }
            ocrComparisonResults.removeFirst(ocrComparisonResults.count - 500)
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
                let debugAccessibilityScreenshotExists = result.debugAccessibilityScreenshotPath == nil || FileManager.default.fileExists(atPath: result.debugAccessibilityScreenshotPath!)
                return screenshotExists && debugScreenshotExists && debugAccessibilityScreenshotExists
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
        let tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
        let ocrFolder = tempPath.appendingPathComponent("OCRScreenshots")
        
        guard let files = try? FileManager.default.contentsOfDirectory(at: ocrFolder, includingPropertiesForKeys: [.creationDateKey]) else {
            return
        }
        
        let currentPaths = Set(ocrComparisonResults.compactMap { $0.screenshotPath } +
                              ocrComparisonResults.compactMap { $0.debugScreenshotPath } +
                              ocrComparisonResults.compactMap { $0.debugAccessibilityScreenshotPath })
        
        // Remove files that are no longer referenced
        for file in files {
            if !currentPaths.contains(file.path) {
                try? FileManager.default.removeItem(at: file)
                print("Cleaned up orphaned screenshot: \(file.lastPathComponent)")
            }
        }
    }

    private func performOCRComparison(for windowElement: AXUIElement) async {
        guard let pid = windowElement.pid() else { return }
        guard !Task.isCancelled else {
            print("performOCRComparison: task cancelled at start")
            return
        }
   
        let startTime = CFAbsoluteTimeGetCurrent()
        let initializationStartTime = CFAbsoluteTimeGetCurrent()
        let appName = windowElement.appName() ?? "Unknown"
        let appTitle = WindowHelpers.getWindowName(window: windowElement)
        let windowFrame = windowElement.getFrame()
        let documentRootDomain = windowElement.documentRootDomain()

        var accessibilityResults: [String: String] = [:]
        var accessibilityBoundingBoxes: [TextBoundingBox]? = nil
        var ocrObservations: [OCRTextObservation] = []
        var ocrImage: CGImage? = nil
        let initializationEndTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - Initialization parse took: \(initializationEndTime - initializationStartTime) seconds")

        // Get accessibility data first (must be on MainActor)
        let axParseStartTime = CFAbsoluteTimeGetCurrent()
        var results: [String: String] = [:]
        var boundingBoxes: [TextBoundingBox]? = nil 
        do {
            (results, boundingBoxes) = try await AccessibilityParser.shared.getAllTextInElement(windowElement: windowElement, includeBoundingBoxes: true)
        } catch {
            print("ocrTiming - AXParsing timed out")
            return
        }
        accessibilityResults = results
        accessibilityBoundingBoxes = boundingBoxes
        guard !Task.isCancelled else {
            print("ocrTiming - task cancelled after accessibility parsing")
            return
        }
        let axParseEndTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - Accessibility parse took: \(axParseEndTime - axParseStartTime) seconds")
        
        // Then get OCR data (can be on OCRActor)
        let ocrStartTime = CFAbsoluteTimeGetCurrent()
        do {
            let (observations, image) = try await OCRManager.shared.extractTextFromApp(appName, appTitle: appTitle, windowFrame: windowFrame)
            ocrObservations = observations
            ocrImage = image
        } catch {
            print("OCR extraction failed: \(error)")
            return
        }
        
        guard !Task.isCancelled else {
            print("ocrTiming - task cancelled after OCR processing")
            return
        }
        let ocrEndTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - OCR took: \(ocrEndTime - ocrStartTime) seconds")
        
        let heavy2StartTime = CFAbsoluteTimeGetCurrent()
        let accessibilityText = accessibilityResults["screen"] ?? ""
        let computationResult = await Task {
            await self.performHeavyComputation(
                observations: ocrObservations,
                screenshot: ocrImage,
                accessibilityText: accessibilityText,
                accessibilityBoundingBoxes: accessibilityBoundingBoxes,
                appName: appName,
                appTitle: appTitle,
                pid: pid
            )
        }.value
        
        // Only add result if computation completed successfully and wasn't cancelled
        self.addOCRComparisonResult(computationResult)

        AnalyticsManager.Debug.ocrComparisonCompleted(appName: appName, matchPercentage: computationResult.matchPercentage, documentRootDomain: documentRootDomain)
        // Send failure event if match percentage is less than 50%
        if computationResult.matchPercentage < 50 {
            AnalyticsManager.Debug.ocrComparisonFailed(appName: appName, matchPercentage: computationResult.matchPercentage, documentRootDomain: documentRootDomain)
        }
        
        let heavy2EndTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - Heavy2 took: \(heavy2EndTime - heavy2StartTime) seconds")
        
        let endTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - Total OCR comparison took: \(endTime - startTime) seconds")
    }
    
    private nonisolated func performHeavyComputation(
        observations: [OCRTextObservation],
        screenshot: CGImage?,
        accessibilityText: String,
        accessibilityBoundingBoxes: [TextBoundingBox]?,
        appName: String,
        appTitle: String,
        pid: pid_t
    ) async -> OCRComparisonResult {
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Create a mutable copy of observations
        var ocrObservations = observations
        
        let comparisonAllStartTime = CFAbsoluteTimeGetCurrent()
        // Extract all OCR words and get matching results
        var allOCRWords: [String] = []
        for observation in ocrObservations {
            let words = extractTokens(from: observation.text)
            allOCRWords.append(contentsOf: words)
        }
        
        let wordMatchResults = await MainActor.run {
            String.findMatchingWords(ocrWords: allOCRWords, accessibilityWords: extractTokens(from: accessibilityText), maxDistance: 2)
        }
        
        let comparisonAllEndTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - performHeavyComputation - ALL text comparison took: \(comparisonAllEndTime - comparisonAllStartTime) seconds")
        
        // Now process individual observations using the batch results
        let observationProcessingStartTime = CFAbsoluteTimeGetCurrent()
        var matchedWords = 0
        var totalWords = 0
        
        for i in 0..<ocrObservations.count {
            let ocrWords = extractTokens(from: ocrObservations[i].text)
            let wordsInObservation = ocrWords.count
            
            // Count how many words in this observation were matched
            let matchedWordsInObservation = ocrWords.filter { word in
                wordMatchResults.contains(word)
            }.count
            
            let observationPercentage = wordsInObservation > 0 ?
                Int((Double(matchedWordsInObservation) / Double(wordsInObservation)) * 100.0) : 0
            
            ocrObservations[i].isFoundInAccessibility = observationPercentage >= 80
            ocrObservations[i].percentageMatched = observationPercentage
            
            matchedWords += matchedWordsInObservation
            totalWords += wordsInObservation
        }
        let observationProcessingEndTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - performHeavyComputation - Observation processing took: \(observationProcessingEndTime - observationProcessingStartTime) seconds")
        
        let matchPercentage = totalWords > 0 ? Int((Double(matchedWords) / Double(totalWords)) * 100.0) : 0
        
        let imageStartTime = CFAbsoluteTimeGetCurrent()
        let failedObservations = ocrObservations.filter { !$0.isFoundInAccessibility }
        
        let debugScreenshot = WindowCaptureOCR().createDebugImage(
            original: screenshot!,
            failedObservations: failedObservations
        )
        
        let debugAccessibilityScreenshot = WindowCaptureOCR().createAccessibilityDebugImage(
            original: screenshot!,
            accessibilityBoundingBoxes: accessibilityBoundingBoxes ?? []
        )
        let imageEndTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - performHeavyComputation - Debug image creation took: \(imageEndTime - imageStartTime) seconds")
        
        print("Total words: \(totalWords), Matched: \(matchedWords), Percentage: \(matchPercentage)%")
        
        // Save all images concurrently on background threads
        let resultId = UUID()
        let nsScreenshot = NSImage(cgImage: screenshot!, size: NSSize(width: screenshot!.width, height: screenshot!.height))
        
        let saveStartTime = CFAbsoluteTimeGetCurrent()
        async let screenshotPath = ImageUtilities.saveImageToDisk(nsScreenshot, prefix: "screenshot_\(resultId.uuidString)")
        async let debugScreenshotPath = ImageUtilities.saveImageToDisk(debugScreenshot, prefix: "debug_\(resultId.uuidString)")
        async let debugAccessibilityScreenshotPath = ImageUtilities.saveImageToDisk(debugAccessibilityScreenshot, prefix: "debug_accessibility_\(resultId.uuidString)")
        
        // Wait for all three saves to complete
        let (savedScreenshotPath, savedDebugScreenshotPath, savedDebugAccessibilityScreenshotPath) = await (screenshotPath, debugScreenshotPath, debugAccessibilityScreenshotPath)
        
        let saveEndTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - Image saving took: \(saveEndTime - saveStartTime) seconds")
        
        let endTime = CFAbsoluteTimeGetCurrent()
        print("ocrTiming - performHeavyComputation took: \(endTime - startTime) seconds")
        
        return OCRComparisonResult(
            appName: appName,
            appTitle: appTitle,
            matchPercentage: matchPercentage,
            accessibilityText: accessibilityText,
            ocrObservations: ocrObservations,
            screenshotPath: savedScreenshotPath,
            debugScreenshotPath: savedDebugScreenshotPath,
            debugAccessibilityScreenshotPath: savedDebugAccessibilityScreenshotPath,
            appBundleUrl: NSRunningApplication(processIdentifier: pid)?.bundleURL
        )
    }
    
    private nonisolated func extractTokens(from text: String) -> [String] {
        let delimiters = CharacterSet(charactersIn: " \t\n\r(){}[]<>.,;:!@#$%^&*+=|\\\"'`~?/-")
        
        let basicTokens = text.components(separatedBy: delimiters)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { $0.count > 1 }
        
        var allTokens = Set(basicTokens)
        
        let genericPatterns = [
            "\\w+\\(\\)",           // Function calls: print(), len(), etc.
            "\\w+\\[\\]",           // Array/list types: int[], Array[], etc.
            "\\w+\\{\\}",           // Object/dict literals: {}, Object{}
            "\\.\\w+",              // Property/method access: .length, .size, .frame
            "\\w+\\.\\w+",          // Namespace/module access: Math.max, os.path
            "#\\w+",                // Hash tags, preprocessor directives: #include, #define
            "\\$\\w+",              // Variables: $var (PHP, Bash), $state (SwiftUI)
            "@\\w+",                // Decorators/annotations: @override, @State
            "\\w+\\?",              // Optionals/nullable: String?, Optional
            "\\w+!",                // Non-null/force unwrap: value!, required
            "//.*",                 // Single line comments
            "/\\*.*\\*/",           // Multi-line comments (simple)
            "<!--.*-->",            // HTML comments
            "\"[^\"]*\"",           // String literals
            "'[^']*'",              // String literals (single quotes)
            "`[^`]*`",              // Template literals/backticks
            "\\d+\\.\\d+",          // Decimal numbers
            "\\w+:\\w+",            // Key-value pairs, labels: name:value
            "\\w+=\\w+",            // Assignments: var=value
            "\\w+\\+=\\w+",         // Compound assignments
            "\\w+->\\w+",           // Arrow functions, pointers: ->
            "\\w+=>\\w+",           // Arrow functions: =>
            "::\\w+",               // Scope resolution: ::method (C++)
            "\\w+<\\w+>",           // Generics/templates: List<String>
        ]
        
        for pattern in genericPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if let range = Range(match.range, in: text) {
                        let matchedToken = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if matchedToken.count > 1 {
                            allTokens.insert(matchedToken)
                        }
                    }
                }
            }
        }
        
        let compoundSeparators = ["_", "-"]
        for token in basicTokens {
            for separator in compoundSeparators {
                if token.contains(separator) {
                    allTokens.insert(token)
                    let parts = token.components(separatedBy: separator).filter { $0.count > 1 }
                    allTokens.formUnion(parts)
                }
            }
        }
        
        return Array(allTokens)
    }
    
    private func compareOCRWithAutoContext(ocrWords: [String], accessibilityWords: [String]) async -> [String: Bool] {
        guard !ocrWords.isEmpty, !accessibilityWords.isEmpty else { return [:] }
        
        // Use GPU-accelerated matching if available
        let matchingWords = await MainActor.run {
            String.findMatchingWords(ocrWords: ocrWords, accessibilityWords: accessibilityWords, maxDistance: 2)
        }
        
        // Create a dictionary mapping each word to whether it was matched
        let matchingWordsSet = Set(matchingWords)
        var wordMatchResults: [String: Bool] = [:]
        
        for word in ocrWords {
            wordMatchResults[word] = matchingWordsSet.contains(word)
        }
        
        return wordMatchResults
    }
    
    private func findBestMatchInAccessibilityText(ocrText: String, accessibilityText: String) -> String? {
        let ocrLength = ocrText.count
        let accessibilityLength = accessibilityText.count
        let maxDistance = Int(Double(ocrLength) * 0.1)
        
        guard ocrLength <= accessibilityLength else { return nil }
        
        for i in 0...(accessibilityLength - ocrLength) {
            let startIndex = accessibilityText.index(accessibilityText.startIndex, offsetBy: i)
            let endIndex = accessibilityText.index(startIndex, offsetBy: ocrLength)
            let subtext = String(accessibilityText[startIndex..<endIndex])
            
            let distance = ocrText.earlyExitLevenshteinDistance(to: subtext, maxAllowableDistance: maxDistance)
            if let distance = distance, distance <= maxDistance {
                return subtext
            }
        }
        return nil
    }
    
    private func calculateMaxDistance(for token: String) -> Int {
        let length = token.count
        if length <= 6 {
            return min(2, length / 3)
        }
        
        if length <= 12 {
            return min(3, length / 4)
        }
    
        return min(5, length / 4)
    }
}
