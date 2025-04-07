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
    let title: String
    
    static func == (lhs: TrackedWindow, rhs: TrackedWindow) -> Bool {
        return lhs.pid == rhs.pid && lhs.hash == rhs.hash
    }
}

class AccessibilityWindowsManager {
    
    @Published private(set) var activeTrackedWindow: TrackedWindow?
    private var trackedWindows: [TrackedWindow] = []
    
    init() {
        print("WindowsManager: init")
        // TODO: KNA - Do it in a task
        for app in NSWorkspace.shared.runningApplications {
            let windows = Self.getWindows(for: app.processIdentifier)
            
            trackedWindows.append(contentsOf: windows)
        }
        print("WindowsManager: end init. Total: \(trackedWindows.count)")
    }
    
    func append(_ element: AXUIElement, pid: pid_t) {
        if let window = element.findWindow(), window.subrole() == "AXStandardWindow" {
            let title = window.title() ?? "NA"
            let trackedWindow = TrackedWindow(element: window, pid: pid, hash: CFHash(window), title: title)
            
            if !trackedWindows.contains(trackedWindow) {
                trackedWindows.append(trackedWindow)
                print("WindowsManager: Window added \(trackedWindow.hash). Total: \(trackedWindows.count)")
            }
            activeTrackedWindow = trackedWindow
        }
    }
    
    func remove(_ trackedWindow: TrackedWindow) {
        if let index = trackedWindows.firstIndex(of: trackedWindow) {
            trackedWindows.remove(at: index)
            print("WindowsManager: Window removed \(trackedWindow.hash). Total: \(trackedWindows.count)")
        }
    }
    
    func trackedWindows(for element: AXUIElement) -> [TrackedWindow] {
        return trackedWindows.filter { $0.hash == CFHash(element) }
    }
    
    static func getWindows(for pid: pid_t) -> [TrackedWindow] {
        let appElement = AXUIElementCreateApplication(pid)
        var result: [TrackedWindow] = []
        
        var windows: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windows) == .success,
           let array = windows as? [AXUIElement] {
            
            for window in array {
                let subrole = window.subrole()
                if subrole == "AXStandardWindow" {
                    let title = window.title() ?? "NA"
                    result.append(TrackedWindow(element: window, pid: pid, hash: CFHash(window), title: title))
                }
            }
        }

        return result
    }
}
