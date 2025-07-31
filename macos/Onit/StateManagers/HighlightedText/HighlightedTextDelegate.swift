//
//  HighlightedTextDelegate.swift
//  Onit
//
//  Created by TimL on 07/29/2025.
//

import Foundation

@MainActor
protocol HighlightedTextDelegate: AnyObject {
    /// Called when highlighted text has changed
    /// - Parameters:
    ///   - selectedText: The newly selected text, or nil if text was deselected
    ///   - application: The name of the application where the text was selected
    func highlightedTextManager(_ manager: HighlightedTextManager, didChange selectedText: String?, application: String?)
}
