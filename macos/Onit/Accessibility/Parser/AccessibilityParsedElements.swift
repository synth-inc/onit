//
//  AccessibilityParsedElements.swift
//  Onit
//
//  Created by Kévin Naudin on 23/01/2025.
//

import Foundation

struct AccessibilityParsedElements {
    static let applicationName = "applicationName"
    static let applicationTitle = "applicationTitle"
    static let elapsedTime = "elapsedTime"

    static let highlightedText = "highlightedText"
    static let screen = "screen"

    struct Xcode {
        static let editor = "editor"
    }
}

struct TextBoundingBox {
    let text: String
    let boundingBox: CGRect
    let elementRole: String?
    let elementDescription: String?
}
