//
//  ProcessIdentifier+Helper.swift
//  Onit
//
//  Created by Kévin Naudin on 24/01/2025.
//

import ApplicationServices
import Foundation
import SwiftUI

extension pid_t {
    func getAXUIElement() -> AXUIElement {
        return AXUIElementCreateApplication(self)
    }
    
    func getFocusedWindow() -> AXUIElement? {
        return getAXUIElement().focusedWindow()
    }

    func getAppName() -> String? {
        NSRunningApplication(processIdentifier: self)?.localizedName
    }
    
    var bundleIdentifier: String? {
        NSRunningApplication(processIdentifier: self)?.bundleIdentifier
    }
}
