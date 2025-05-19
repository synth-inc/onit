//
//  ProcessIdentifier+Helper.swift
//  Onit
//
//  Created by Kévin Naudin on 24/01/2025.
//

import ApplicationServices

extension pid_t {
    
    func getAXUIElement() -> AXUIElement {
        let appElement = AXUIElementCreateApplication(self)
        
        // This makes sure the AX server is fully initialized
        _ = appElement.role()
        
        return appElement
    }
    
    func getRootChildren() -> [AXUIElement] {
        return getAXUIElement().children() ?? []
    }
    
    private func findTargetWindows() -> [AXUIElement] {
        let windows = self.getRootChildren()
        var targetWindows : [AXUIElement] = []
        
        for window in windows {
            if window.isTargetWindow() {
                targetWindows.append(window)
            }
        }
        
        return targetWindows
    }
    
    var firstMainWindow: AXUIElement? {
        let windows = findTargetWindows()

        // Try to find a suitable window in this priority order:
        // 1. A single main window from target windows
        // 2. The application's mainWindow if it's in our target windows
        // 3. The application's focusedWindow if it's in our target windows

        // First, check if there's exactly one main window in the target windows
        let mainWindows = windows.filter { $0.isMain() == true }
        
        if mainWindows.count == 1 {
            return mainWindows.first
        }

        let application = getAXUIElement()
        
        // If no single main window, try the application's mainWindow
        if let mainWindow = application.mainWindow(), windows.contains(where: {
            CFHash($0) == CFHash(mainWindow)
        }) {
            return mainWindow
        }

        // If no main window, try the application's focusedWindow
        if let focusedWindow = application.focusedWindow(), windows.contains(where: {
            CFHash($0) == CFHash(focusedWindow)
        }) {
            return focusedWindow
        }

        return nil
    }
    
    // We should not use this function in most cases.
    // kAXWindowsAttribute is OPTIONAL and may applications do not implement it, including Apple default apps like Notes
    // Instead we should use getRootChildren() followed by filtering with isValidWindow().
    func getWindows() -> [AXUIElement] {
        let appElement = getAXUIElement()
        
        var windowList: CFArray?
        let result = AXUIElementCopyAttributeValues(appElement, kAXWindowsAttribute as CFString, 0, 1, &windowList)
        
        guard result == .success,
              let windows = windowList as? [AXUIElement] else {
            return [appElement]
        }
        
        return windows
    }
}
