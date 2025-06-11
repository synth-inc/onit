//
//  PanelStatePinnedManager+Resize.swift
//  Onit
//
//  Created by Kévin Naudin on 14/05/2025.
//

import AppKit
import Defaults

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

            let resizeMode = Defaults[.pinnedResizeMode]

            let panelWidth = state.panelWidth - (TetheredButton.width / 2) + 1
            let screenFrame = screen.visibleFrame
            let availableSpace = screenFrame.maxX - windowFrame.maxX

            if resizeMode == .all {
                if targetInitialFrames[window] == nil {
                    // This is situation where new window enters our screen but hadn't previously been moved handle later.
                    if windowFrameChanged {
                        
//                        let newWidth = windowFrame.width + panelWidth
//                        let newFrame = NSRect(origin: windowFrame.origin,
//                                              size: NSSize(width: newWidth, height: windowFrame.height))
//                        targetInitialFrames[window] = newFrame
                    } else {
                        targetInitialFrames[window] = windowFrame
                    }

                    let newWidth = windowFrame.width - panelWidth
                    let newFrame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: newWidth, height: windowFrame.height)
                    print("resizeWindow - App \(window.title() ?? ""), og width: \(windowFrame.width), new width: \(newWidth)")
                    _ = window.setFrame(newFrame)
                }
                
                // This is the situation where we're already tracking it and it's move. What's the behavior here?
                // If we drag it under the panel, we probably want to resize it.
            
                // Check if window is Xcode and print frame
//                if let appname = window.appName(), appname.lowercased().contains("xcode") == true {
//                    print("Xcode window new frame: \(newFrame)")
//                }

            } else if !isPanelResized {
                if availableSpace < panelWidth {
                    if !windowFrameChanged {
                        print("resizeWindow - Saving initial frame!! \(windowFrame)")
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
                    print("resizeWindow - setting new frame!! \(newFrame)")
                    _ = window.setFrame(newFrame)
//                } else if availableSpace > panelWidth, windowFrameChanged {
//                    // The user reduced the window, we should remove the initial frame
//                    print("resizeWindow - removing target frame")
//                    targetInitialFrames.removeValue(forKey: window)
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
