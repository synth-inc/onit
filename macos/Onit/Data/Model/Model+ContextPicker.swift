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
        OverlayManager.shared.showOverlay(model: self, content: ContextPickerView())
    }

    func closeContextPickerOverlay() {
        OverlayManager.shared.dismissOverlay()
    }
}
