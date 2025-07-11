//
//  PanelStatePinnedManager+Resize.swift
//  Onit
//
//  Created by Kévin Naudin on 14/05/2025.
//

import AppKit

extension PanelStatePinnedManager {
    
    func resizeWindows(for screen: NSScreen, isPanelResized: Bool = false) {
        guard !isResizingWindows else { return }

        isResizingWindows = true

        // First, handle the foregroundWindow if it exists
        if let foregroundWindow = state.foregroundWindow {
            resizeWindow(for: screen, window: foregroundWindow.element, isPanelResized: isPanelResized)
        }

        // Then, handle all other windows, skipping the foregroundWindow if present
        let windows = WindowHelpers.getAllOtherAppWindows()
        for window in windows {
            if let foregroundWindow = state.foregroundWindow, window == foregroundWindow.element {
                continue
            }
            DispatchQueue.main.async {
                self.resizeWindow(for: screen, window: window, isPanelResized: isPanelResized)
            }
        }
        isResizingWindows = false
    }
    func resizeWindow(
        for screen: NSScreen,
        window: AXUIElement,
        windowFrameChanged: Bool = false,
        isPanelResized: Bool = false
    ) {
        if !windowFrameChanged, !isPanelResized { guard !targetInitialFrames.keys.contains(window) else { return } }
        if !shouldResizeWindows { return }
        
        if let windowFrameConverted = window.getFrame(convertedToGlobalCoordinateSpace: true),
           let windowScreen = windowFrameConverted.findScreen(),
           windowScreen == screen,
           let windowFrame = window.getFrame() {
            
            let panelWidth = state.panelWidth - (TetheredButton.width / 2) + 1
            let screenFrame = screen.visibleFrame
            
            let newWidth = (screenFrame.maxX - windowFrame.origin.x) - panelWidth
            let newFrame = CGRect(x: windowFrame.origin.x, y:windowFrame.origin.y, width: newWidth, height: windowFrame.height)
            _ = window.setFrame(newFrame)
        }
    }
}
