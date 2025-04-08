//
//  Model+ModelSelection.swift
//  Onit
//
//  Created by Timl on 2/28/25.
//

import AppKit
import Defaults
import SwiftUI

@MainActor
class OverlayManager {
    static let shared = OverlayManager()
    private var currentOverlay: OverlayWindowController<AnyView>?
    private var clickPosition: NSPoint?

    /// Captures the current mouse position for later use
    func captureClickPosition() {
        clickPosition = NSEvent.mouseLocation
    }
    
    /// Presents a new overlay by dismissing any existing one.
    func showOverlay<Content: View>(content: Content) {
        // Dismiss the current overlay (if any)
        currentOverlay?.closeOverlay()
        currentOverlay = nil
        
        // Create and store the new overlay
        let overlay = OverlayWindowController(content: AnyView(content), clickPosition: clickPosition)
        currentOverlay = overlay
        
        // Reset click position after use
        clickPosition = nil
    }
    
    /// Dismisses the current overlay.
    func dismissOverlay() {
        currentOverlay?.closeOverlay()
        currentOverlay = nil
    }
}
