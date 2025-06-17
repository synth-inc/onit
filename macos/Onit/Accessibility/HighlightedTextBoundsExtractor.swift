import Foundation
import ApplicationServices
import AppKit

enum HighlightedTextBoundsMethod {
    case bounds
    case font
    case approximation
    case element
}

struct HighlightedTextBoundsResult {
    let elementFrame: CGRect
    let elementRole: String
    let highlightedText: String
    let highlightedTextFrame: CGRect
    let method: HighlightedTextBoundsMethod
}

struct TextPaddingInfo {
    let topPadding: CGFloat
    let leftPadding: CGFloat
    let rightPadding: CGFloat
    let bottomPadding: CGFloat
    let method: TextPaddingMethod
}

enum TextPaddingMethod {
    case boundsForRange
    case visibleRange
    case firstCharacter
    case estimation
}

@MainActor
class HighlightedTextBoundsExtractor {
    
    static let shared = HighlightedTextBoundsExtractor()
    
    private var lastUsedElement: AXUIElement?
    private var lastSelectedText: String?
    private var lastResult: HighlightedTextBoundsResult?
    
    private init() {}
    
    func getBounds(for element: AXUIElement, selectedText: String) -> HighlightedTextBoundsResult? {
        return extractBounds(from: element, selectedText: selectedText)
    }
    
    func getLastUsedElement() -> AXUIElement? {
        return lastUsedElement
    }
    
    func getLastResult() -> HighlightedTextBoundsResult? {
        return lastResult
    }
    
    func reset() {
        lastUsedElement = nil
        lastSelectedText = nil
        lastResult = nil
    }
    
    // MARK: - Private Functions
    
    private func extractBounds(from element: AXUIElement, selectedText: String) -> HighlightedTextBoundsResult? {
        let targetText = selectedText
        
        guard let textElement = findTextElement(in: element, containing: targetText) else {
            log.error("return nil")
            return nil
        }
        
        let result = getExactSelectionBounds(from: textElement, selectedText: targetText)
        
        lastUsedElement = textElement
        lastSelectedText = targetText
        lastResult = result
        
        return result
    }
    
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
    
    private func getExactSelectionBounds(from element: AXUIElement, selectedText: String) -> HighlightedTextBoundsResult? {
        let elementFrame = element.getFrame() ?? CGRect.zero
        let elementRole = element.role() ?? "Unknown"
        
        if let exactBounds = element.selectedTextBound(),
           exactBounds.width > 0 && exactBounds.height > 0 {
            let adjustedBounds = adjustBoundsToRequirements(
                originalBounds: exactBounds,
                elementFrame: elementFrame,
                selectedText: selectedText
            )

            return HighlightedTextBoundsResult(
                elementFrame: elementFrame,
                elementRole: elementRole,
                highlightedText: selectedText,
                highlightedTextFrame: adjustedBounds,
                method: .bounds
            )
        }
        
        if let fontBasedBounds = calculateBoundsUsingFont(element: element, selectedText: selectedText) {
            return HighlightedTextBoundsResult(
                elementFrame: elementFrame,
                elementRole: elementRole,
                highlightedText: selectedText,
                highlightedTextFrame: fontBasedBounds,
                method: .font
            )
        }
        
        if let calculatedBounds = calculateApproximateBounds(element: element, selectedText: selectedText) {
            return HighlightedTextBoundsResult(
                elementFrame: elementFrame,
                elementRole: elementRole,
                highlightedText: selectedText,
                highlightedTextFrame: calculatedBounds,
                method: .approximation
            )
        }
        
        return HighlightedTextBoundsResult(
            elementFrame: elementFrame,
            elementRole: elementRole,
            highlightedText: selectedText,
            highlightedTextFrame: elementFrame,
            method: .element
        )
    }
    
    private func calculateTextPadding(for element: AXUIElement) -> TextPaddingInfo? {
        guard let elementFrame = element.getFrame() else { return nil }
        
        if let boundsBasedPadding = calculatePaddingUsingBoundsForRange(element: element, elementFrame: elementFrame) {
            return boundsBasedPadding
        }
        
        if let visibleRangePadding = calculatePaddingUsingVisibleRange(element: element, elementFrame: elementFrame) {
            return visibleRangePadding
        }
        
        if let firstCharPadding = calculatePaddingUsingFirstCharacter(element: element, elementFrame: elementFrame) {
            return firstCharPadding
        }
        
        return estimateTextPadding(element: element, elementFrame: elementFrame)
    }
    
    private func calculatePaddingUsingBoundsForRange(element: AXUIElement, elementFrame: CGRect) -> TextPaddingInfo? {
        guard let text = element.value(), !text.isEmpty else { return nil }
        
        var cfRange = CFRange(location: 0, length: 1)
        guard let rangeValue = AXValueCreate(.cfRange, &cfRange) else { return nil }
        
        var bounds: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue,
            &bounds
        ) == .success else {
            return nil
        }
        
        let boundsValue = bounds as! AXValue
        var firstCharRect = CGRect.zero
        AXValueGetValue(boundsValue, .cgRect, &firstCharRect)
        
        let leftPadding = firstCharRect.origin.x - elementFrame.origin.x
        let topPadding = firstCharRect.origin.y - elementFrame.origin.y
        
        let rightPadding = max(0, elementFrame.maxX - firstCharRect.maxX)
        let bottomPadding = max(0, elementFrame.maxY - firstCharRect.maxY)
        
        return TextPaddingInfo(
            topPadding: max(0, topPadding),
            leftPadding: max(0, leftPadding),
            rightPadding: rightPadding,
            bottomPadding: bottomPadding,
            method: .boundsForRange
        )
    }
    
    private func calculatePaddingUsingVisibleRange(element: AXUIElement, elementFrame: CGRect) -> TextPaddingInfo? {
        var visibleRange: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXVisibleCharacterRangeAttribute as CFString,
            &visibleRange
        ) == .success else {
            return nil
        }
        
        var cfRange = CFRange()
        AXValueGetValue(visibleRange as! AXValue, .cfRange, &cfRange)
        
        if cfRange.location == 0 && cfRange.length > 0 {
            var bounds: CFTypeRef?
            guard AXUIElementCopyParameterizedAttributeValue(
                element,
                kAXBoundsForRangeParameterizedAttribute as CFString,
                visibleRange as CFTypeRef,
                &bounds
            ) == .success else {
                return nil
            }
            
            let boundsValue = bounds as! AXValue
            var visibleTextRect = CGRect.zero
            AXValueGetValue(boundsValue, .cgRect, &visibleTextRect)
            
            let leftPadding = visibleTextRect.origin.x - elementFrame.origin.x
            let topPadding = visibleTextRect.origin.y - elementFrame.origin.y
            let rightPadding = elementFrame.maxX - visibleTextRect.maxX
            let bottomPadding = elementFrame.maxY - visibleTextRect.maxY
            
            return TextPaddingInfo(
                topPadding: max(0, topPadding),
                leftPadding: max(0, leftPadding),
                rightPadding: max(0, rightPadding),
                bottomPadding: max(0, bottomPadding),
                method: .visibleRange
            )
        }
        
        return nil
    }
    
    private func calculatePaddingUsingFirstCharacter(element: AXUIElement, elementFrame: CGRect) -> TextPaddingInfo? {
        guard let text = element.value(), !text.isEmpty else { return nil }
        
        var firstCharIndex = 0
        for (index, char) in text.enumerated() {
            if !char.isWhitespace {
                firstCharIndex = index
                break
            }
        }
        
        var cfRange = CFRange(location: firstCharIndex, length: 1)
        guard let rangeValue = AXValueCreate(.cfRange, &cfRange) else { return nil }
        
        var bounds: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXBoundsForRangeParameterizedAttribute as CFString,
            rangeValue,
            &bounds
        ) == .success else {
            return nil
        }
        
        let boundsValue = bounds as! AXValue
        var charRect = CGRect.zero
        AXValueGetValue(boundsValue, .cgRect, &charRect)
        
        let leftPadding = charRect.origin.x - elementFrame.origin.x
        let topPadding = charRect.origin.y - elementFrame.origin.y
        
        return TextPaddingInfo(
            topPadding: max(0, topPadding),
            leftPadding: max(0, leftPadding),
            rightPadding: 10,
            bottomPadding: 5,
            method: .firstCharacter
        )
    }
    
    private func estimateTextPadding(element: AXUIElement, elementFrame: CGRect) -> TextPaddingInfo {
        let elementRole = element.role() ?? ""
        
        let (horizontal, vertical) = estimatePaddingForRole(elementRole, elementFrame: elementFrame)
        
        return TextPaddingInfo(
            topPadding: vertical,
            leftPadding: horizontal,
            rightPadding: horizontal,
            bottomPadding: vertical,
            method: .estimation
        )
    }
    
    private func estimatePaddingForRole(_ role: String, elementFrame: CGRect) -> (horizontal: CGFloat, vertical: CGFloat) {
        switch role {
        case kAXTextFieldRole:
            return (5.0, 3.0)
            
        case kAXTextAreaRole:
            return (8.0, 5.0)
            
        case kAXStaticTextRole:
            return (2.0, 1.0)
            
        case "AXWebArea":
            return (10.0, 8.0)
            
        default:
            let size = max(elementFrame.width, elementFrame.height)
            if size < 50 {
                return (2.0, 1.0)
            } else if size < 200 {
                return (5.0, 3.0)
            } else {
                return (10.0, 8.0)
            }
        }
    }
    
    private func adjustBoundsToRequirements(originalBounds: CGRect, elementFrame: CGRect, selectedText: String) -> CGRect {
        let selectedTextLines = selectedText.components(separatedBy: .newlines)
        let numberOfSelectedLines = selectedTextLines.count
        
        let lineHeight = originalBounds.height / CGFloat(numberOfSelectedLines)
        
        return CGRect(
            x: elementFrame.origin.x,
            y: originalBounds.origin.y,
            width: elementFrame.width,
            height: CGFloat(numberOfSelectedLines) * lineHeight
        )
    }
    
    private func calculateBoundsUsingFont(element: AXUIElement, selectedText: String) -> CGRect? {
        guard let elementFrame = element.getFrame(),
              let fullText = element.value() else {
            return nil
        }
        
        guard let range = fullText.range(of: selectedText) else {
            return nil
        }
        
        let nsRange = NSRange(location: 0, length: 1)
        
        guard let fontInfo = extractFontFromSelectedText(element: element, range: nsRange) else {
            return nil
        }
        
        let font = fontInfo.font
        let lineHeight = fontInfo.lineHeight
        
        let textBeforeSelection = String(fullText[..<range.lowerBound])
        
        let lines = textBeforeSelection.components(separatedBy: .newlines)
        let currentLine = lines.count - 1
        
        let selectionLines = selectedText.components(separatedBy: .newlines)
        let numberOfSelectedLines = selectionLines.count
        
        let x = elementFrame.origin.x
        let y = elementFrame.origin.y + CGFloat(currentLine) * lineHeight
        let width = elementFrame.width
        let height = CGFloat(numberOfSelectedLines) * lineHeight
        
        let selectionFrame = CGRect(
            x: x,
            y: max(y, elementFrame.origin.y),
            width: width,
            height: min(height, elementFrame.height - (y - elementFrame.origin.y))
        )
        
        return selectionFrame
    }
    
    private func extractFontFromSelectedText(element: AXUIElement, range: NSRange) -> (font: NSFont, lineHeight: CGFloat)? {
        var cfRange = CFRange(location: range.location, length: range.length)
        let rangeValue = AXValueCreate(.cfRange, &cfRange)
        
        guard let rangeValue = rangeValue else { return nil }
        
        var attributedStringResult: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXAttributedStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &attributedStringResult
        ) == .success else {
            return nil
        }
        
        guard let attributedString = attributedStringResult as? NSAttributedString,
              attributedString.length > 0 else {
            return nil
        }
        
        let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
        
        guard let font = attributes[.font] as? NSFont else {
            return nil
        }
        
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
    
    private func calculateTextSize(_ text: String, with font: NSFont) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        return attributedString.size()
    }
    
    private func calculateApproximateBounds(element: AXUIElement, selectedText: String) -> CGRect? {
        guard let elementFrame = element.getFrame(),
              let fullText = element.value() else {
            return nil
        }
        
        guard let range = fullText.range(of: selectedText) else {
            return nil
        }
        
        let textPadding = calculateTextPadding(for: element)
        let paddingInfo = textPadding ?? TextPaddingInfo(
            topPadding: 5, leftPadding: 5, rightPadding: 5, bottomPadding: 5,
            method: .estimation
        )
        
        let textAreaFrame = CGRect(
            x: elementFrame.origin.x + paddingInfo.leftPadding,
            y: elementFrame.origin.y + paddingInfo.topPadding,
            width: elementFrame.width - paddingInfo.leftPadding - paddingInfo.rightPadding,
            height: elementFrame.height - paddingInfo.topPadding - paddingInfo.bottomPadding
        )
        
        let fontMetrics = estimateFontMetrics(for: element)
        
        let wrappedMetrics = calculateWrappedTextMetrics(
            fullText: fullText,
            selectedText: selectedText,
            range: range,
            elementFrame: textAreaFrame,
            fontMetrics: fontMetrics
        )
        
        let selectedTextLines = selectedText.components(separatedBy: .newlines)
        let numberOfSelectedLines = selectedTextLines.count
        
        let selectionFrame = CGRect(
            x: elementFrame.origin.x,
            y: textAreaFrame.origin.y + wrappedMetrics.offsetY,
            width: elementFrame.width,
            height: CGFloat(numberOfSelectedLines) * fontMetrics.lineHeight
        )
        
        let clampedFrame = CGRect(
            x: selectionFrame.origin.x,
            y: max(selectionFrame.origin.y, elementFrame.origin.y),
            width: selectionFrame.width,
            height: min(selectionFrame.height, elementFrame.height - (selectionFrame.origin.y - elementFrame.origin.y))
        )
        
        return clampedFrame
    }
    
    private struct FontMetrics {
        let charWidth: CGFloat
        let lineHeight: CGFloat
        let baseline: CGFloat
        let spaceWidth: CGFloat
    }
    
    private struct WrappedTextMetrics {
        let offsetX: CGFloat
        let offsetY: CGFloat
        let width: CGFloat
        let height: CGFloat
    }
    
    private func estimateFontMetrics(for element: AXUIElement) -> FontMetrics {
        let elementRole = element.role() ?? ""
        let elementFrame = element.getFrame() ?? CGRect.zero
        
        if let fontInfo = extractFontFromSelectedText(element: element, range: NSRange(location: 0, length: min(1, element.value()?.count ?? 0))) {
            let font = fontInfo.font
            let spaceSize = calculateTextSize(" ", with: font)
            let charSize = calculateTextSize("M", with: font)
            
            return FontMetrics(
                charWidth: charSize.width,
                lineHeight: fontInfo.lineHeight,
                baseline: font.ascender,
                spaceWidth: spaceSize.width
            )
        }
        
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
        
        let charWidth = estimatedFontSize * 0.6
        let lineHeight = estimatedFontSize * 1.3
        let spaceWidth = estimatedFontSize * 0.25
        
        return FontMetrics(
            charWidth: charWidth,
            lineHeight: lineHeight,
            baseline: estimatedFontSize * 0.8,
            spaceWidth: spaceWidth
        )
    }
    
    private func calculateWrappedTextMetrics(
        fullText: String,
        selectedText: String,
        range: Range<String.Index>,
        elementFrame: CGRect,
        fontMetrics: FontMetrics
    ) -> WrappedTextMetrics {
        
        let textBeforeSelection = String(fullText[..<range.lowerBound])
        let availableWidth = elementFrame.width - 20
        
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        
        let paragraphs = textBeforeSelection.components(separatedBy: .newlines)
        
        for (paragraphIndex, paragraph) in paragraphs.enumerated() {
            if paragraphIndex > 0 {
                currentY += fontMetrics.lineHeight
                currentX = 0
            }
            
            let words = paragraph.components(separatedBy: .whitespaces)
            
            for (wordIndex, word) in words.enumerated() {
                if wordIndex > 0 {
                    currentX += fontMetrics.spaceWidth
                    
                    if currentX >= availableWidth {
                        currentY += fontMetrics.lineHeight
                        currentX = 0
                    }
                }
                
                let wordWidth = CGFloat(word.count) * fontMetrics.charWidth
                
                if currentX + wordWidth > availableWidth && currentX > 0 {
                    currentY += fontMetrics.lineHeight
                    currentX = 0
                }
                
                currentX += wordWidth
            }
        }
        
        let selectedTextLines = selectedText.components(separatedBy: .newlines)
        let selectionWidth: CGFloat
        let selectionHeight: CGFloat
        
        if selectedTextLines.count == 1 {
            let estimatedWidth = CGFloat(selectedText.count) * fontMetrics.charWidth
            selectionWidth = min(estimatedWidth, availableWidth - currentX)
            selectionHeight = fontMetrics.lineHeight
        } else {
            let maxLineWidth = selectedTextLines.max { line1, line2 in
                line1.count < line2.count
            }?.count ?? 0
            
            selectionWidth = min(CGFloat(maxLineWidth) * fontMetrics.charWidth, availableWidth)
            selectionHeight = CGFloat(selectedTextLines.count) * fontMetrics.lineHeight
        }
        
        return WrappedTextMetrics(
            offsetX: currentX,
            offsetY: currentY,
            width: max(selectionWidth, fontMetrics.charWidth),
            height: max(selectionHeight, fontMetrics.lineHeight)
        )
    }
}
