//
//  AXUIElementFontExtractor.swift
//  Onit
//
//  Created by Kévin Naudin on 08/04/2025.
//

import Foundation
import AppKit
import ApplicationServices

@MainActor
class AXUIElementFontExtractor {
    
    // MARK: - FontProperties
    
    struct FontProperties {
        let font: NSFont
        let fontSize: CGFloat
        let lineHeight: CGFloat
    }
    
    // MARK: - Properties
    
    private static let defaultFont = NSFont.systemFont(ofSize: 13, weight: .regular)
    private static let defaultFontSize: CGFloat = 13
    private static let defaultLineHeight: CGFloat = 16
    static let defaultFontProperties = FontProperties(
        font: defaultFont,
        fontSize: defaultFontSize,
        lineHeight: defaultLineHeight
    )
    
    // MARK: - Public Functions
    
    static func getFontProperties(for element: AXUIElement) -> FontProperties {
        if let accessibilityFont = getAccessibilityFont(for: element) {
            return accessibilityFont
        }
        
        return defaultFontProperties
    }
    
    // MARK: - Private Functions
    
    private static func getAccessibilityFont(for element: AXUIElement) -> FontProperties? {
        if let attributedString = getAttributedString(for: element) {
            return extractFontFromAttributedString(attributedString)
        }
        
        if let value = element.value(), !value.isEmpty {
            return extractFontFromTextValue(element, text: value)
        }
        
        return nil
    }
    
    private static func extractFontFromTextValue(_ element: AXUIElement, text: String) -> FontProperties? {
        guard let cursorIndex = element.selectedTextRange()?.location else {
            return nil
        }
        
        let safeCursorIndex = max(0, min(cursorIndex, text.count - 1))
        var range = CFRangeMake(safeCursorIndex, 1)
        
        guard let rangeValue = AXValueCreate(.cfRange, &range) else {
            return nil
        }
        
        var attributedText: CFTypeRef?
        let result = AXUIElementCopyParameterizedAttributeValue(
            element,
            kAXAttributedStringForRangeParameterizedAttribute as CFString,
            rangeValue,
            &attributedText
        )
        
        if result == .success,
           let attrString = attributedText as? NSAttributedString,
           attrString.length > 0 {
            return extractFontFromAttributedString(attrString)
        }
        
        return nil
    }
    
    private static func getAttributedString(for element: AXUIElement) -> NSAttributedString? {
        if let attributedString = element.attribute(forAttribute: "AXAttributedString" as CFString) as? NSAttributedString,
           attributedString.length > 0 {
            return attributedString
        }
        
        return nil
    }
    
    private static func extractFontFromAttributedString(_ attributedString: NSAttributedString) -> FontProperties? {
        guard attributedString.length > 0 else { return nil }
        
        let attributes = attributedString.attributes(at: 0, effectiveRange: nil)
        let fontKey = NSAttributedString.Key(rawValue: "AXFont")
        
        guard let fontDict = attributes[fontKey] as? [String: Any] else { return nil }
        
        let fontName = (fontDict["AXFontName"] as? String) ?? defaultFont.fontName
        let fontSize = (fontDict["AXFontSize"] as? CGFloat) ?? defaultFontSize
        
        guard let nsFont = NSFont(name: fontName, size: fontSize) else {
            return nil
        }
        
        return FontProperties(
            font: nsFont,
            fontSize: fontSize,
            lineHeight: calculateLineHeight(for: nsFont)
        )
    }
    
    private static func calculateLineHeight(for font: NSFont) -> CGFloat {
        let naturalLineHeight = font.ascender - font.descender
        let lineSpacing = naturalLineHeight * 0.2 // 20% spacing
        
        return naturalLineHeight + lineSpacing
    }
}
