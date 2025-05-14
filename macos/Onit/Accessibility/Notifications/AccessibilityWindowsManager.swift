//
//  AccessibilityWindowsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 07/04/2025.
//

import ApplicationServices
import SwiftUI

struct TrackedWindow: Hashable {
    let element: AXUIElement
    let pid: pid_t
    let hash: UInt
    var title: String
    
    static func == (lhs: TrackedWindow, rhs: TrackedWindow) -> Bool {
        return lhs.pid == rhs.pid && lhs.hash == rhs.hash
    }
}

enum TrackedWindowAction {
    case undefined
    case activate
    case move
    case moveEnd
    case moveAutomatically
    case resize
}

@MainActor
class AccessibilityWindowsManager {
    var activeTrackedWindow: TrackedWindow?
    
    private var trackedWindows: [TrackedWindow] = []
    
    func append(_ element: AXUIElement, pid: pid_t) -> TrackedWindow? {
        if element.isDesktopFinder {
            let trackedWindow = TrackedWindow(element: element, pid: pid, hash: CFHash(element), title: "")
            
            if !trackedWindows.contains(trackedWindow) {
                trackedWindows.append(trackedWindow)
            }
            activeTrackedWindow = trackedWindow
            
            return trackedWindow
        } else {
            // Get the application and target windows. 
            let windows = element.findTargetWindows()
            let application = AXUIElementCreateApplication(pid)
            
            // Try to find a suitable window in this priority order:
            // 1. A single main window from target windows
            // 2. The application's mainWindow if it's in our target windows
            // 3. The application's focusedWindow if it's in our target windows
            // 4. The first window in the target windows list
            
            var selectedWindow: AXUIElement? = nil
            
            // First, check if there's exactly one main window in the target windows
            let mainWindows = windows.filter { $0.isMain() == true }
            if mainWindows.count == 1 {
                selectedWindow = mainWindows.first
            }
            
            // If no single main window, try the application's mainWindow
            if selectedWindow == nil, 
               let mainWindow = application.mainWindow(), 
               windows.contains(where: { CFHash($0) == CFHash(mainWindow) }) {
                selectedWindow = mainWindow
            }
            
            // If no main window, try the application's focusedWindow
            if selectedWindow == nil, 
               let focusedWindow = application.focusedWindow(), 
               windows.contains(where: { CFHash($0) == CFHash(focusedWindow) }) {
                selectedWindow = focusedWindow
            }
            
            // If all else fails, take the first window
            if selectedWindow == nil {
                selectedWindow = windows.first
            }
            
            // Create and return a TrackedWindow if we found a suitable window
            if let window = selectedWindow {
                let title = window.title() ?? "NA"
                let trackedWindow = TrackedWindow(element: window, pid: pid, hash: CFHash(window), title: title)
                
                if !trackedWindows.contains(trackedWindow) {
                    trackedWindows.append(trackedWindow)
                }
                activeTrackedWindow = trackedWindow
                return trackedWindow
            } else {
                return nil
            }
        }
    }
    
    func remove(_ trackedWindow: TrackedWindow) -> TrackedWindow? {
        if let index = trackedWindows.firstIndex(of: trackedWindow) {
            trackedWindows.remove(at: index)
            return trackedWindow
        }
        return nil
    }
    
    func trackedWindows(for element: AXUIElement) -> [TrackedWindow] {
        return trackedWindows.filter { $0.hash == CFHash(element) }
    }
}
