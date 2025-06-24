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
        
        let onitName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        let appPids = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .filter { $0.localizedName != onitName }
            .map { $0.processIdentifier }
         
        for pid in appPids {
            let windows = pid.findTargetWindows()
            
            for window in windows {
                resizeWindow(for: screen, window: window, isPanelResized: isPanelResized)
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
        
        if let windowFrameConverted = window.getFrame(convertedToGlobalCoordinateSpace: true),
           let windowScreen = windowFrameConverted.findScreen(),
           windowScreen == screen,
           let windowFrame = window.getFrame() {
            
            let panelWidth = state.panelWidth - (TetheredButton.width / 2) + 1
            let screenFrame = screen.visibleFrame
            let availableSpace = screenFrame.maxX - windowFrame.maxX
            
            if !isPanelResized {
                if availableSpace < panelWidth {
                    if !windowFrameChanged {
                        targetInitialFrames[window] = windowFrame
                    } else if targetInitialFrames[window] == nil {
                        // The user resize the window, we should store the initial frame containing the panel space.
                        let newWidth = windowFrame.width + panelWidth
                        let newFrame = NSRect(origin: windowFrame.origin,
                                              size: NSSize(width: newWidth, height: windowFrame.height))
                        
                        targetInitialFrames[window] = newFrame
                    }
                    let overlapAmount = panelWidth - availableSpace
                    let newWidth = windowFrame.width - overlapAmount
                    let newFrame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: newWidth, height: windowFrame.height)
                    _ = window.setFrame(newFrame)
                }
            } else {
                // If we're already tracking it, then make it move.
                if targetInitialFrames.keys.contains(window) {
                    let newWidth = (screenFrame.maxX - windowFrame.origin.x) - panelWidth
                    let newFrame = CGRect(x: windowFrame.origin.x, y:windowFrame.origin.y, width: newWidth, height: windowFrame.height)
                    _ = window.setFrame(newFrame)
                } else if availableSpace < panelWidth {
                    // If we aren't already tracking it and it now needs to get resized, start tracking it.
                    targetInitialFrames[window] = windowFrame
                    let overlapAmount = panelWidth - availableSpace
                    let newWidth = windowFrame.width - overlapAmount
                    let newFrame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: newWidth, height: windowFrame.height)
                    _ = window.setFrame(newFrame)
                }
                
            }
        }
    }
}
