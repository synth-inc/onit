//
//  AXUIElement+Onit.swift
//  Onit
//
//  Created by Timothy Lenardo on 4/14/25.
//

@preconcurrency import ApplicationServices

extension AXUIElement {
    
    // We are currently using this but should instead use findTargetWindows with some logic to select to correct one. 
    public func findFirstTargetWindow() -> AXUIElement? {
        let windows = self.getRootChildren()
        for window in windows {
            if isTargetWindow(window) {
                return window
            }
        }
        return nil
    }

    public func findTargetWindows() -> [AXUIElement] {
        var toRet : [AXUIElement] = []
        let windows = self.getRootChildren()
        for window in windows {
            if isTargetWindow(window) {
                toRet.append(window)
            }
        }
        return toRet
    }
    
    public func isTargetWindow(_ window: AXUIElement) -> Bool {
        guard window.subrole() == "AXStandardWindow" else {
            return false
        }
        return window.closeButton() != nil && window.minimizeButton() != nil && window.zoomButton() != nil
    }
}
