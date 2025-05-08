//
//  OnitPanel.swift
//  Onit
//
//  Created by Kévin Naudin on 27/03/2025.
//

import Defaults
import SwiftUI

protocol OnitPanel: NSPanel {
    
    func setLevel(_ level: NSWindow.Level)
    
    @MainActor
    func show()
    
    @MainActor
    func hide()
    
    var dragDetails: PanelDraggingDetails { get set }
    var wasAnimated: Bool { get set }
    var animatedFromLeft: Bool { get set }
    var resizedApplication: Bool { get set }
    var isAnimating: Bool { get set }
}

extension OnitPanel {
    
    func findScreen() -> NSScreen? {
        if Defaults[.openOnMouseMonitor] {
            return NSScreen.mouse
        } else {
            return screen ?? NSScreen.screens.first
        }
    }
}
