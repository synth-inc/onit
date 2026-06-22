//
//  HintManager+Detections.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Functions: Observing SwiftUI View Frame Changes
 * Public Functions: Click Inside Detection
 */

import AppKit
import Foundation

extension HintManager {
    // MARK: - Functions: Observing SwiftUI View Frame Changes
    
    /// Allows the hint to dynamically react to size updates in its associated SwiftUI view: `Hint.swift`.
    func configureFrameChangeObserver(for hostingView: NSView) {
        hostingView.postsFrameChangedNotifications = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contentViewFrameDidChange),
            name: NSView.frameDidChangeNotification,
            object: hostingView
        )
    }

    /// Handle content view frame changes to update window position
    @objc private func contentViewFrameDidChange(_ notification: Notification) {
        guard !isHandlingFrameChange else { return }

        let previousSize = currentHintSize
        
        updateHintSize()

        let hintSizeChanged = currentHintSize != previousSize

        guard hintSizeChanged else { return }

        isHandlingFrameChange = true

        repositionHintToRightEdge()

        isHandlingFrameChange = false
    }
    
    // MARK: - Public Functions: Click Inside Detection

    /// Check if a click location is inside the hint window or menu window
    func isClickInsideWindows(_ screenLocation: NSPoint) -> Bool {
        /// Check hint window.
        if hintWindow.frame.contains(screenLocation) {
            return true
        }

        /// Check menu window.
        if let moreMenuWindow = moreMenuWindow,
           moreMenuWindowIsVisible
        {
            if moreMenuWindow.frame.contains(screenLocation) {
                return true
            }
        }

        return false
    }
}
