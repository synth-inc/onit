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
    private var panelPositionObserver: NSObjectProtocol?
    
    private init() {
        // Observe changes to panel position setting
        panelPositionObserver = NotificationCenter.default.addObserver(
            forName: Defaults.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let key = notification.userInfo?[Defaults.keyPathKey] as? Defaults.Key<PanelPosition>,
                  key == .panelPosition else { return }
            self?.updateCurrentOverlayPosition()
        }
    }
    
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

    private func updateCurrentOverlayPosition() {
        guard let overlay = currentOverlay else { return }
        overlay.updatePosition()
    }

    deinit {
        if let observer = panelPositionObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
}
