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
    case resizeEnd
}

@MainActor
class AccessibilityWindowsManager {
    var activeTrackedWindow: TrackedWindow?
    
    private var destroyedTrackedWindow: TrackedWindow?
    private var trackedWindows: [TrackedWindow] = []
    
    func append(_ element: AXUIElement, pid: pid_t) -> TrackedWindow? {
        if element.isDesktopFinder {
            let trackedWindow = TrackedWindow(element: element, pid: pid, hash: CFHash(element), title: "")
            
            if !trackedWindows.contains(trackedWindow) {
                trackedWindows.append(trackedWindow)
            }
            activeTrackedWindow = trackedWindow
            
            return trackedWindow
        } else if element.isTargetWindow() {

            let title = element.title() ?? "NA"
            let trackedWindow = TrackedWindow(element: element, pid: pid, hash: CFHash(element), title: title)
            
            if !trackedWindows.contains(trackedWindow) {
                trackedWindows.append(trackedWindow)
            }
            activeTrackedWindow = trackedWindow
            return trackedWindow
        } else {
            log.debug("Skipping append for element with role \(element.role() ?? "") title: \(element.title() ?? "")")
        }
        
        return nil
    }
    
    func remove(_ trackedWindow: TrackedWindow) -> TrackedWindow? {
        if let index = trackedWindows.firstIndex(of: trackedWindow) {
            trackedWindows.remove(at: index)
            
            destroyedTrackedWindow = trackedWindow
            return trackedWindow
        }
        return nil
    }
    
    func trackedWindows(for element: AXUIElement) -> [TrackedWindow] {
        return trackedWindows.filter { $0.hash == CFHash(element) }
    }
}
