//
//  OnitPanel.swift
//  Onit
//
//  Created by Kévin Naudin on 27/03/2025.
//

import Defaults
import SwiftUI

protocol OnitPanel: NSPanel {
    
    @MainActor
    func adjustSize()
    
    @MainActor
    func toggleFullscreen()
    
    @MainActor
    func updatePosition()
    
    @MainActor
    func show()
    
    @MainActor
    func hide()
}

extension OnitPanel {
    
    func findScreen() -> NSScreen? {
        if Defaults[.openOnMouseMonitor] {
            return NSScreen.screens.first(where: { screen in
                let mouseLocation = NSEvent.mouseLocation
                return screen.frame.contains(mouseLocation)
            })
        } else {
            return screen ?? NSScreen.screens.first
        }
    }
}
