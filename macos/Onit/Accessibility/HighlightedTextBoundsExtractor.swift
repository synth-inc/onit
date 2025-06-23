import Foundation
import ApplicationServices
import AppKit

enum HighlightedTextBoundsMethod {
    case selectedTextBound
    case fontCalculation
    case approximation
}

struct HighlightedTextBoundsResult {
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
    
    private init() {}
    
    // MARK: - Functions
    
    func getBounds(for element: AXUIElement, selectedText: String) -> HighlightedTextBoundsResult? {
        guard let textElement = findTextElement(in: element, containing: selectedText) else {
            return nil
        }
        
        let result = calculateBounds(for: textElement, selectedText: selectedText)
        
        lastSelectedText = selectedText
        lastResult = result
        
        return result
    }
    
    func getLastResult() -> HighlightedTextBoundsResult? {
        return lastResult
    }
    
    func reset() {
        lastSelectedText = nil
        lastResult = nil
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
    
    private func calculateBounds(for element: AXUIElement, selectedText: String) -> HighlightedTextBoundsResult? {
        let appName = element.pid()?.appName ?? "Unknown"
        let elementFrame = element.getFrame() ?? CGRect.zero
        let elementRole = element.role() ?? "Unknown"
        let x = element.firstGroupParent()?.getFrame()?.origin.x ?? elementFrame.origin.x
        let width = elementFrame.width
        
        var finalFrame: CGRect
        var methodUsed: HighlightedTextBoundsMethod
        
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
        } else if let fontBasedFrame = calculateFrameUsingFont(
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
        } else if let approximateFrame = calculateFrameUsingFont(
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
}
