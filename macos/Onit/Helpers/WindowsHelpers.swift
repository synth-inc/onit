//
//  WindowsHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 5/12/25.
//

import AppKit

func setOnboardingAuthWindowToFloat() {
    DispatchQueue.main.asyncAfter(deadline: .now()) {
        let windowIdentifier = NSUserInterfaceItemIdentifier(windowOnboardingAuthId)
        
        if let window = NSApp.windows.first(where: { $0.identifier == windowIdentifier }) {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}
