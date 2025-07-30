//
//  FocusedTextFieldDelegate.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/29/25.
//

import Foundation
import ApplicationServices

@MainActor
protocol FocusedTextFieldDelegate: AnyObject {
    /// Called when the focused text field changes.
    /// - Parameter textField: The currently focused AXUIElement, or nil if none.
    func focusedTextFieldDidChange(_ textField: AXUIElement?)
}
