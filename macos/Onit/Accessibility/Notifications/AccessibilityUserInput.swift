//
//  AccessibilityUserInput.swift
//  Onit
//
//  Created by Kévin Naudin on 14/02/2025.
//

import SwiftUI

/// Structure containing information about the user input fetch from Accessibility
struct AccessibilityUserInput {
    var fullText: String = ""
    var precedingText: String = ""
    var followingText: String = ""
    var cursorPosition: Int = -1
    
    static let empty = AccessibilityUserInput()
    
    private init() { }
    
    init(fullText: String, precedingText: String, followingText: String, cursorPosition: Int) {
        self.fullText = fullText
        self.precedingText = precedingText
        self.followingText = followingText
        self.cursorPosition = cursorPosition
    }
}

extension AccessibilityUserInput: Equatable {
    static func == (lhs: AccessibilityUserInput, rhs: AccessibilityUserInput) -> Bool {
        lhs.fullText == rhs.fullText && lhs.precedingText == rhs.precedingText &&
        lhs.followingText == rhs.followingText && lhs.cursorPosition == rhs.cursorPosition
    }
}
