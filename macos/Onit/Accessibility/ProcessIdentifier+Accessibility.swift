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
    
    func findTargetWindows() -> [AXUIElement] {
        let windows = self.getRootChildren()
        var targetWindows : [AXUIElement] = []
        
        for window in windows {
            if window.isTargetWindow() {
                targetWindows.append(window)
            }
        }
        
        return targetWindows
    }
    
    // We are currently using this but should instead use findTargetWindows with some logic to select to correct one.
    func findFirstTargetWindow() -> AXUIElement? {
        return self.findTargetWindows().first
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
    
    func getFocusedWindow() -> AXUIElement? {
        let appElement = getAXUIElement()
        
        if let value = appElement.attribute(forAttribute: kAXFocusedWindowAttribute as CFString) {
            return (value as! AXUIElement)
        }
        
        return nil
    }
}
