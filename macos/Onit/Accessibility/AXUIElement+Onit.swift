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
            if window.isTargetWindow() {
                return window
            }
        }
        return nil
    }
    
    public func findTargetWindows() -> [AXUIElement] {
        var targetWindows : [AXUIElement] = []
        let windows = self.getRootChildren()
        for window in windows {
            if window.isTargetWindow() {
                targetWindows.append(window)
            }
        }
        return targetWindows
    }
    
    public func isTargetWindow() -> Bool {
        guard self.subrole() == "AXStandardWindow" else {
            return false
        }
        return self.closeButton() != nil && self.minimizeButton() != nil && self.zoomButton() != nil
    }
}
