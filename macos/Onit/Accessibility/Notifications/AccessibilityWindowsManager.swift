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

@MainActor protocol AccessibilityWindowsManagerDelegate: AnyObject {
    func windowsManager(_ manager: AccessibilityWindowsManager, didActivateWindow window: TrackedWindow)
    func windowsManager(_ manager: AccessibilityWindowsManager, didDestroyWindow window: TrackedWindow)
}

@MainActor
class AccessibilityWindowsManager {
    
    weak var delegate: AccessibilityWindowsManagerDelegate?
    
    var activeTrackedWindow: TrackedWindow?
    private var destroyedTrackedWindow: TrackedWindow?
    private var trackedWindows: [TrackedWindow] = []
    
    func append(_ element: AXUIElement, pid: pid_t) {
        if TetherAppsManager.isFinderShowingDesktopOnly(activeWindow: element) {
            let trackedWindow = TrackedWindow(element: element, pid: pid, hash: CFHash(element), title: "")
            
            if !trackedWindows.contains(trackedWindow) {
                trackedWindows.append(trackedWindow)
            }
            activeTrackedWindow = trackedWindow
                
            delegate?.windowsManager(self, didActivateWindow: trackedWindow)
        } else if let window = element.findFirstTargetWindow() {

            let title = window.title() ?? "NA"
            let trackedWindow = TrackedWindow(element: window, pid: pid, hash: CFHash(window), title: title)
            
            if !trackedWindows.contains(trackedWindow) {
                trackedWindows.append(trackedWindow)
            }
            activeTrackedWindow = trackedWindow
                
            delegate?.windowsManager(self, didActivateWindow: trackedWindow)
        }
    }
    
    func remove(_ trackedWindow: TrackedWindow) {
        if let index = trackedWindows.firstIndex(of: trackedWindow) {
            trackedWindows.remove(at: index)
            
            destroyedTrackedWindow = trackedWindow

            delegate?.windowsManager(self, didDestroyWindow: trackedWindow)
        }
    }
    
    func trackedWindows(for element: AXUIElement) -> [TrackedWindow] {
        return trackedWindows.filter { $0.hash == CFHash(element) }
    }
}
