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

        // First, handle the bordering windows if they exists
        let borderingWindows = findBorderingWindows().compactMap { $0 }
        for window in borderingWindows {
            resizeWindow(for: screen, window: window, isPanelResized: isPanelResized)
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
        // We pass when the panel is in the process of closing.
        if !shouldResizeWindows { return }
        
        if let windowFrameConverted = window.getFrame(convertedToGlobalCoordinateSpace: true),
           let windowScreen = windowFrameConverted.findScreen(),
           windowScreen == screen,
           let windowFrame = window.getFrame() {
            
            let panelWidth = state.panelWidth - (TetheredButton.width / 2) + 1
            let screenFrame = screen.visibleFrame
            let availableSpace = screenFrame.maxX - windowFrame.maxX
            
            // Only resize when the window occupies the same space as the panel. 
            if availableSpace < panelWidth {
                let overlapAmount = panelWidth - availableSpace
                let newWidth = windowFrame.width - overlapAmount
                let newFrame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: newWidth, height: windowFrame.height)
                _ = window.setFrame(newFrame)
            }
        }
    }
    
    func findBorderingWindows() -> [AXUIElement?] {
        guard let screenFrame = self.attachedScreen?.visibleFrame ?? NSScreen.main?.visibleFrame else { return [] }
        let panelWidth = state.panelWidth - (TetheredButton.width / 2) + 1
        let panelMinX = screenFrame.maxX - panelWidth
        let panelYMin = screenFrame.minY
        let panelYMax = screenFrame.maxY

        // We'll sample 10 points evenly along the vertical edge of the panel, 2px outside the panel's left edge
        let sampleCount = 10
        let x = panelMinX - 2
        let step = (panelYMax - panelYMin) / CGFloat(sampleCount - 1)
        var foundWindows: [AXUIElement] = []

        for i in 0..<sampleCount {
            let y = panelYMin + CGFloat(i) * step
            let point = CGPoint(x: x, y: y)

            // Perform hit test at this point
            if let element = AXUIElementCreateSystemWide().accessibilityHitTest(point) {
                // Try to get the window containing this element
                if let window = element.findContainingTargetWindow() {
                    // Only add if not already present
                    if !foundWindows.contains(where: { $0 == window }) {
                        foundWindows.append(window)
                    }
                }
            }
        }

        return foundWindows.map { Optional($0) }
    }
}
