import Foundation
import ApplicationServices
import AppKit
import Vision

enum HighlightedTextBoundsMethod: Sendable {
    case selectedTextBound
    case fontCalculation
    case ocrDetection
    case approximation
}

struct OCRLine: Sendable {
    let text: String
    let boundingBox: CGRect
    let confidence: Float
}

struct HighlightedTextBoundsResult: @unchecked Sendable {
    let appName: String
    let element: AXUIElement
    let elementFrame: CGRect
    let elementRole: String
    let highlightedText: String
    let highlightedTextFrame: CGRect
    let method: HighlightedTextBoundsMethod
}

@MainActor
class HighlightedTextBoundsExtractor {
    
    static let shared = HighlightedTextBoundsExtractor()
    
    private var lastSelectedText: String?
    private var lastResult: HighlightedTextBoundsResult?
    
    private var currentTask: Task<HighlightedTextBoundsResult?, Never>?
    
    struct OCRConfig {
        static let useAccurateRecognition = true
        static let enableLanguageCorrection = false
        static let minimumTextConfidence: Float = 0.5
    }
    
    private init() {}
    
    // MARK: - Functions
    
    func getBounds(for element: AXUIElement, selectedText: String) async -> HighlightedTextBoundsResult? {
        if currentTask != nil {
            print("HighlightedTextBounds: Cancelling previous task for '\(selectedText.prefix(20))...'")
            currentTask?.cancel()
        }
        
        print("HighlightedTextBounds: Starting new task for '\(selectedText.prefix(20))...'")
        currentTask = Task { @MainActor in
            guard let textElement = findTextElement(in: element, containing: selectedText) else {
                return nil
            }
            
            let result = await calculateBounds(for: textElement, selectedText: selectedText)
            
            guard !Task.isCancelled else {
                print("HighlightedTextBounds: Task was cancelled for '\(selectedText.prefix(20))...'")
                return nil
            }
            
            return result
        }
        
        let result = await currentTask?.value
        
        if let result = result {
            print("HighlightedTextBounds: Task completed successfully for '\(selectedText.prefix(20))...'")
            lastSelectedText = selectedText
            lastResult = result
        } else {
            print("HighlightedTextBounds: Task returned nil for '\(selectedText.prefix(20))...'")
        }
        
        return result
    }
    
    
    
    func getLastResult() -> HighlightedTextBoundsResult? {
        return lastResult
    }
    
    func reset() {
        lastSelectedText = nil
        lastResult = nil
        cancelCurrentTask()
    }
    
    func cancelCurrentTask() {
        currentTask?.cancel()
        currentTask = nil
        print("HighlightedTextBounds: Current task cancelled")
    }
    
    // MARK: - Private Functions
    
    private func findTextElement(in element: AXUIElement, containing selectedText: String, depth: Int = 0) -> AXUIElement? {
        guard depth < 20 else { return nil }
        
        let supportedRoles = [kAXStaticTextRole, kAXTextAreaRole, kAXTextFieldRole]
        let currentRole = element.role() ?? ""
        
        if supportedRoles.contains(currentRole) {
            let elementValue = element.value() ?? ""
            let elementSelectedText = element.selectedText() ?? ""
            
            if elementValue.contains(selectedText) || elementSelectedText == selectedText {
                return element
            }
        }
        
        guard let children = element.children() else { return nil }
        
        for child in children {
            if let foundElement = findTextElement(in: child, containing: selectedText, depth: depth + 1) {
                return foundElement
            }
        }
        
        return nil
    }
    
    private func calculateBounds(for element: AXUIElement, selectedText: String) async -> HighlightedTextBoundsResult? {
        let appName = element.pid()?.appName ?? "Unknown"
        let elementFrame = element.getFrame() ?? CGRect.zero
        let elementRole = element.role() ?? "Unknown"
        let firstGroupParent = element.firstGroupParent()
        let x = firstGroupParent?.getFrame()?.origin.x ?? elementFrame.origin.x
        let width = elementFrame.width
        
        var finalFrame: CGRect
        var methodUsed: HighlightedTextBoundsMethod
        
        // 1: selectedTextBound
        if let selectedBounds = element.selectedTextBound(),
           selectedBounds.width > 0,
           selectedBounds.height > 0 {
            finalFrame = CGRect(
                x: x,
                y: selectedBounds.origin.y,
                width: width,
                height: selectedBounds.height
            )
            methodUsed = .selectedTextBound
        }
        // 2: fontCalculation
        else if let fontBasedFrame = calculateFrameUsingFont(
            element: element,
            selectedText: selectedText,
            useApproximation: false
        ) {
            finalFrame = CGRect(
                x: x,
                y: fontBasedFrame.origin.y,
                width: width,
                height: fontBasedFrame.height
            )
            methodUsed = .fontCalculation
        }
        // 3: OCR
        else if let firstGroupParent = firstGroupParent,
                let ocrFrame = await calculateFrameUsingOCR(
                    element: firstGroupParent,
                    selectedText: selectedText
                ) {
            finalFrame = CGRect(
                x: x,
                y: ocrFrame.origin.y,
                width: width,
                height: ocrFrame.height
            )
            methodUsed = .ocrDetection
        }
        // 4: approximation (fallback)
        else if let approximateFrame = calculateFrameUsingFont(
            element: element,
            selectedText: selectedText,
            useApproximation: true
        ) {
            finalFrame = CGRect(
                x: x,
                y: approximateFrame.origin.y,
                width: width,
                height: approximateFrame.height
            )
            methodUsed = .approximation
        } else {
            finalFrame = elementFrame
            methodUsed = .approximation
        }
        
        return HighlightedTextBoundsResult(
            appName: appName,
            element: element,
            elementFrame: elementFrame,
            elementRole: elementRole,
            highlightedText: selectedText,
            highlightedTextFrame: finalFrame,
            method: methodUsed
        )
    }
    
    private func calculateFrameUsingFont(element: AXUIElement, selectedText: String, useApproximation: Bool) -> CGRect? {
        guard let elementFrame = element.getFrame(),
              let fullText = element.value(),
              let range = fullText.range(of: selectedText) else {
            return nil
        }
        
        let lineHeight: CGFloat
        
        if useApproximation {
            lineHeight = estimateLineHeight(for: element)
        } else {
            guard let fontInfo = extractFont(from: element) else { return nil }
            
            lineHeight = fontInfo.lineHeight
        }
        
        let textBeforeSelection = String(fullText[..<range.lowerBound])
        let linesBeforeSelection = textBeforeSelection.components(separatedBy: .newlines).count - 1
        let selectedTextLines = selectedText.components(separatedBy: .newlines).count
        let y = elementFrame.origin.y + CGFloat(linesBeforeSelection) * lineHeight
        let height = CGFloat(selectedTextLines) * lineHeight
        
        return CGRect(
            x: 0,
            y: max(y, elementFrame.origin.y),
            width: 0,
            height: min(height, elementFrame.height - (y - elementFrame.origin.y))
        )
    }
    
    private func extractFont(from element: AXUIElement) -> (font: NSFont, lineHeight: CGFloat)? {
        var cfRange = CFRange(location: 0, length: 1)
        guard let rangeValue = AXValueCreate(.cfRange, &cfRange) else { return nil }
        
        var attributedStringResult: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXAttributedStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &attributedStringResult) == .success,
              let attributedString = attributedStringResult as? NSAttributedString,
              attributedString.length > 0 else {
            return nil
        }
        
        let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
        guard let font = attributes[.font] as? NSFont else { return nil }
        
        let lineHeight = calculateLineHeight(for: font, with: attributes)
        return (font: font, lineHeight: lineHeight)
    }
    
    private func calculateLineHeight(for font: NSFont, with attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        if let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle,
           paragraphStyle.lineHeightMultiple > 0 {
            return font.pointSize * paragraphStyle.lineHeightMultiple
        }
        return font.pointSize * 1.2
    }
    
    private func estimateLineHeight(for element: AXUIElement) -> CGFloat {
        let elementRole = element.role() ?? ""
        let elementFrame = element.getFrame() ?? CGRect.zero
        
        let estimatedFontSize: CGFloat
        switch elementRole {
        case kAXTextFieldRole:
            estimatedFontSize = max(12.0, min(16.0, elementFrame.height * 0.6))
        case kAXTextAreaRole:
            estimatedFontSize = max(11.0, min(15.0, elementFrame.height * 0.05))
        case kAXStaticTextRole:
            estimatedFontSize = max(10.0, min(18.0, elementFrame.height * 0.7))
        default:
            estimatedFontSize = max(10.0, min(16.0, elementFrame.height * 0.4))
        }
        
        return estimatedFontSize * 1.3
    }
    
    private func calculateFrameUsingOCR(element: AXUIElement, selectedText: String) async -> CGRect? {
        guard let elementFrame = element.getFrame(),
              elementFrame.width > 0,
              elementFrame.height > 0 else {
            return nil
        }
        
        guard let screenshot = await MainActor.run(body: {
            return captureElementScreenshot(frame: elementFrame)
        }) else {
            print("OCR: Failed to capture screenshot for frame \(elementFrame)")
            return nil
        }
        
        guard !Task.isCancelled else {
            print("OCR: Task was cancelled")
            return nil
        }
        
        let result = await performOCRAnalysis(on: screenshot, searchText: selectedText, elementFrame: elementFrame)
        
        guard !Task.isCancelled else {
            print("OCR: Task was cancelled before returning result")
            return nil
        }
        
        return result
    }
    
    private func captureElementScreenshot(frame: CGRect) -> CGImage? {
        guard let displayID = CGMainDisplayID() as CGDirectDisplayID? else {
            return nil
        }
        
        return CGDisplayCreateImage(displayID, rect: frame)
    }
    
    private func performOCRAnalysis(on image: CGImage, searchText: String, elementFrame: CGRect) async -> CGRect? {
        return await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = OCRConfig.useAccurateRecognition ? .accurate : .fast
            request.usesLanguageCorrection = OCRConfig.enableLanguageCorrection
            
            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            
            Task {
                do {
                    guard !Task.isCancelled else {
                        print("OCR: Task cancelled before analysis")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    try handler.perform([request])
                    
                    guard !Task.isCancelled else {
                        print("OCR: Task cancelled after analysis")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    guard let observations = request.results else {
                        print("OCR: No text found in image")
                        continuation.resume(returning: nil)
                        return
                    }
                    
                    let result = await self.findTextBounds(
                        searchText: searchText,
                        observations: observations,
                        elementFrame: elementFrame
                    )
                    continuation.resume(returning: result)
                    
                } catch {
                    print("OCR: Analysis failed - \(error)")
                    continuation.resume(returning: nil)
                }
            }
        }
    }
    
    // MARK: - OCR Algorithm
    
    private func findTextBounds(searchText: String, observations: [VNRecognizedTextObservation], elementFrame: CGRect) async -> CGRect? {
        let cleanSearchText = normalizeText(searchText)
        print("OCR: Searching for '\(cleanSearchText)' in \(observations.count) text regions")
        
        var textRegions: [(text: String, bounds: CGRect, confidence: Float)] = []
        
        for observation in observations {
            guard let candidate = observation.topCandidates(1).first,
                  candidate.confidence >= OCRConfig.minimumTextConfidence else {
                continue
            }
            
            let text = normalizeText(candidate.string)
            let bounds = observation.boundingBox
            textRegions.append((text: text, bounds: bounds, confidence: candidate.confidence))
        }
        
        textRegions.sort { $0.bounds.minY > $1.bounds.minY }
        
        print("OCR: Found \(textRegions.count) valid text regions")
        
        for (index, region) in textRegions.enumerated() {
            print("OCR: Region \(index): '\(region.text)' (confidence: \(String(format: "%.2f", region.confidence)))")
        }
        
        if let exactMatch = findExactMatchInRegions(searchText: cleanSearchText, regions: textRegions) {
            return convertToMacOSBounds(visionBounds: exactMatch, elementFrame: elementFrame)
        }
        
        if let multiMatch = findMultiRegionMatch(searchText: cleanSearchText, regions: textRegions) {
            return convertToMacOSBounds(visionBounds: multiMatch, elementFrame: elementFrame)
        }
        
        if let partialMatch = findPartialMatchInRegions(searchText: cleanSearchText, regions: textRegions) {
            return convertToMacOSBounds(visionBounds: partialMatch, elementFrame: elementFrame)
        }
        
        if let keywordMatch = findKeywordMatchInRegions(searchText: cleanSearchText, regions: textRegions) {
            return convertToMacOSBounds(visionBounds: keywordMatch, elementFrame: elementFrame)
        }
        
        print("OCR: No match found")
        return nil
    }
    
    // MARK: - Search strategies
    
    private func normalizeText(_ text: String) -> String {
        return text
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
    }
    
    private func findExactMatchInRegions(searchText: String, regions: [(text: String, bounds: CGRect, confidence: Float)]) -> CGRect? {
        print("OCR: Looking for exact match in single regions")
        
        for (index, region) in regions.enumerated() {
            if region.text.contains(searchText) {
                print("OCR: ✅ Found exact match in region \(index): '\(region.text.prefix(50))...'")
                return region.bounds
            }
        }
        
        print("OCR: No exact match in single regions")
        return nil
    }
    
    private func findMultiRegionMatch(searchText: String, regions: [(text: String, bounds: CGRect, confidence: Float)]) -> CGRect? {
        print("OCR: Looking for multi-region match")
        
        var bestMatch: (startIndex: Int, endIndex: Int, regionCount: Int)? = nil
        
        for startIndex in 0..<regions.count {
            for endIndex in startIndex..<regions.count {
                let selectedRegions = Array(regions[startIndex...endIndex])
                let combinedText = selectedRegions.map { $0.text }.joined(separator: " ")
                
                if startIndex == 0 {
                    print("OCR: Testing regions \(startIndex)-\(endIndex): '\(combinedText.prefix(100))...' (length: \(combinedText.count))")
                }
                
                if combinedText.contains(searchText) {
                    let regionCount = endIndex - startIndex + 1
                    print("OCR: Found match in regions \(startIndex)-\(endIndex) (\(regionCount) regions)")
                    
                    if bestMatch == nil || regionCount < bestMatch!.regionCount {
                        bestMatch = (startIndex: startIndex, endIndex: endIndex, regionCount: regionCount)
                    }
                }
            }
        }
        
        if let match = bestMatch {
            let selectedRegions = Array(regions[match.startIndex...match.endIndex])
            print("OCR: ✅ Best multi-region match in regions \(match.startIndex)-\(match.endIndex) (\(match.regionCount) regions)")
            return combineBounds(selectedRegions.map { $0.bounds })
        }
        
        print("OCR: No multi-region match")
        return nil
    }
    
    private func findPartialMatchInRegions(searchText: String, regions: [(text: String, bounds: CGRect, confidence: Float)]) -> CGRect? {
        print("OCR: Looking for partial matches")
        
        var bestMatch: (startIndex: Int, endIndex: Int, matchLength: Int, type: String)? = nil
        
        for startIndex in 0..<regions.count {
            for endIndex in startIndex..<regions.count {
                let selectedRegions = Array(regions[startIndex...endIndex])
                let combinedText = selectedRegions.map { $0.text }.joined(separator: " ")
                
                if searchText.hasPrefix(combinedText) && combinedText.count >= searchText.count / 2 {
                    if bestMatch == nil || combinedText.count > bestMatch!.matchLength {
                        bestMatch = (startIndex, endIndex, combinedText.count, "prefix")
                    }
                }
                
                if searchText.hasSuffix(combinedText) && combinedText.count >= searchText.count / 2 {
                    if bestMatch == nil || combinedText.count > bestMatch!.matchLength {
                        bestMatch = (startIndex, endIndex, combinedText.count, "suffix")
                    }
                }
                
                if combinedText.count >= searchText.count / 3 && searchText.contains(combinedText) {
                    if bestMatch == nil || combinedText.count > bestMatch!.matchLength {
                        bestMatch = (startIndex, endIndex, combinedText.count, "partial")
                    }
                }
            }
        }
        
        if let match = bestMatch {
            let selectedRegions = Array(regions[match.startIndex...match.endIndex])
            print("OCR: ✅ Found \(match.type) match in regions \(match.startIndex)-\(match.endIndex) (length: \(match.matchLength))")
            return combineBounds(selectedRegions.map { $0.bounds })
        }
        
        print("OCR: No partial matches")
        return nil
    }
    
    private func findKeywordMatchInRegions(searchText: String, regions: [(text: String, bounds: CGRect, confidence: Float)]) -> CGRect? {
        print("OCR: Looking for keyword matches")
        
        let searchWords = Set(searchText.components(separatedBy: .whitespaces)
            .filter { $0.count >= 3 })
        
        guard !searchWords.isEmpty else {
            print("OCR: No keywords to search for")
            return nil
        }
        
        var bestMatch: (startIndex: Int, endIndex: Int, score: Double, regionCount: Int)? = nil
        
        for startIndex in 0..<regions.count {
            for endIndex in startIndex..<regions.count {
                let selectedRegions = Array(regions[startIndex...endIndex])
                let combinedText = selectedRegions.map { $0.text }.joined(separator: " ")
                let textWords = Set(combinedText.components(separatedBy: .whitespaces))
                
                let matchingWords = searchWords.intersection(textWords)
                let score = Double(matchingWords.count) / Double(searchWords.count)
                
                if score >= 0.6 {
                    let regionCount = endIndex - startIndex + 1
                    
                    if bestMatch == nil ||
                        score > bestMatch!.score ||
                        (score == bestMatch!.score && regionCount < bestMatch!.regionCount) {
                        bestMatch = (startIndex, endIndex, score, regionCount)
                        print("OCR: New best keyword match: \(Int(score*100))% in regions \(startIndex)-\(endIndex) (\(regionCount) regions)")
                    }
                }
            }
        }
        
        if let match = bestMatch {
            let selectedRegions = Array(regions[match.startIndex...match.endIndex])
            print("OCR: ✅ Found keyword match with \(Int(match.score*100))% score in regions \(match.startIndex)-\(match.endIndex)")
            return combineBounds(selectedRegions.map { $0.bounds })
        }
        
        print("OCR: No keyword matches")
        return nil
    }
    
    // MARK: Helper
    
    private func combineBounds(_ bounds: [CGRect]) -> CGRect {
        guard !bounds.isEmpty else { return CGRect.zero }
        
        let minX = bounds.map { $0.minX }.min() ?? 0
        let maxX = bounds.map { $0.maxX }.max() ?? 0
        let minY = bounds.map { $0.minY }.min() ?? 0
        let maxY = bounds.map { $0.maxY }.max() ?? 0
        
        return CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    
    private func convertToMacOSBounds(visionBounds: CGRect, elementFrame: CGRect) -> CGRect {
        let macosY = elementFrame.origin.y + (1 - visionBounds.maxY) * elementFrame.height
        let height = visionBounds.height * elementFrame.height
        
        return CGRect(
            x: elementFrame.origin.x,
            y: macosY,
            width: elementFrame.width,
            height: max(height, 10)
        )
    }
}
