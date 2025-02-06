//
//  Model+ContextPicker.swift
//  Onit
//
//  Created by Kévin Naudin on 25/01/2025.
//

import AppKit
import Foundation
import SwiftUI

extension OnitModel {
    func showContextPickerOverlay() {
        if contextPickerWindowController == nil {
            contextPickerWindowController = OverlayWindowController(
                model: self, content: ContextPickerView())
        } else {
            closeContextPickerOverlay()
        }
    }

    func closeContextPickerOverlay() {
        contextPickerWindowController?.closeOverlay()
        contextPickerWindowController = nil
    }

}
