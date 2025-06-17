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
    
    // When a hashed TrackedWindow is required (e.g. in Sets or Dictionary keys):
    //   1. Make it so that `title` and `element` updates don't contribute to the hash value.
    //   2. Make hashes consistent with == above.
    func hash(into hasher: inout Hasher) {
        hasher.combine(pid)
        hasher.combine(hash)
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
            let trackedWindow = TrackedWindow(
                element: element,
                pid: pid,
                hash: CFHash(element),
                title: ""
            )
            
            addToTrackedWindows(trackedWindow)
            activeTrackedWindow = trackedWindow
            
            return trackedWindow
        }
        
        var targetWindow: AXUIElement?
        
        if element.isMain() == true && element.isTargetWindow() {
            targetWindow = element
        } else if element.isTargetWindow() {
            targetWindow = element
        } else {
            targetWindow = findContainingWindow(element: element, pid: pid)
        }
        
        if let window = targetWindow {
            let trackedWindow = TrackedWindow(
                element: window,
                pid: pid,
                hash: CFHash(window),
                title: WindowHelpers.getWindowName(window: window)
            )
            
            addToTrackedWindows(trackedWindow)
            activeTrackedWindow = trackedWindow
            
            return trackedWindow
        } else {
            log.debug("Skipping append for element with role \(element.role() ?? "") title: \(element.title() ?? "")")
        }
        
        return nil
    }
    
    func addToTrackedWindows(_ trackedWindow: TrackedWindow) {
        if let existingTrackedWindowsIndex = trackedWindows.firstIndex(where: {
            $0.pid == trackedWindow.pid && $0.hash == trackedWindow.hash
        }) {
            trackedWindows[existingTrackedWindowsIndex] = trackedWindow
        } else {
            trackedWindows.append(trackedWindow)
        }
    }
    
    func findTrackedWindow(trackedWindowHash: UInt) -> TrackedWindow? {
        return trackedWindows.first(where: { $0.hash == trackedWindowHash })
    }
    
    private func findContainingWindow(element: AXUIElement, pid: pid_t) -> AXUIElement? {
        var currentElement = element
        
        while let parent = currentElement.parent() {
            if parent.isTargetWindow() {
                return parent
            }
            currentElement = parent
        }
        
        return pid.firstMainWindow
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
    
    func reset() {
        activeTrackedWindow = nil
        trackedWindows.removeAll()
    }
}
