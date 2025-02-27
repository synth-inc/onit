//
//  Model+ModelSelection.swift
//  Onit
//
//  Created by Timl on 2/28/25.
//

import AppKit
import SwiftUI

@MainActor
class OverlayManager {
    static let shared = OverlayManager()
    private var currentOverlay: OverlayWindowController<AnyView>?
    
    private init() {}
    
    /// Presents a new overlay by dismissing any existing one.
    func showOverlay<Content: View>(model: OnitModel, content: Content) {
        // Dismiss the current overlay (if any)
        currentOverlay?.closeOverlay()
        currentOverlay = nil
        
        // Create and store the new overlay
        let overlay = OverlayWindowController(model: model, content: AnyView(content))
        currentOverlay = overlay
        // Additional logic to actually display the overlay if needed
    }
    
    /// Dismisses the current overlay.
    func dismissOverlay() {
        currentOverlay?.closeOverlay()
        currentOverlay = nil
    }
}
