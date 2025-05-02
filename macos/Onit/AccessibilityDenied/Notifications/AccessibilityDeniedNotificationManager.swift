//
//  AccessibilityDeniedNotificationManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 4/23/25.
//

import AppKit
import SwiftUI

// Delegate protocol for notifying about screen panel updates.
@MainActor protocol AccessibilityDeniedNotificationDelegate: AnyObject {
    func accessibilityDeniedNotificationManager(_ manager: AccessibilityDeniedNotificationManager, didActivateScreen screen: TrackedScreen)
}

@MainActor
class AccessibilityDeniedNotificationManager: ObservableObject {
    static let shared = AccessibilityDeniedNotificationManager()

    let trackedScreenManager = TrackedScreenManager()
    var lastScreenFrame = CGRect.zero
    
    weak var delegate: AccessibilityDeniedNotificationDelegate?
        
    private init() { }
    
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    func start() {
        stop()
        
        // Add global monitor to capture mouse moved events
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            handleMouseMoved(event: event)
        }

        // Add local monitor to capture mouse moved events when the application is foregrounded
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return event }
            handleMouseMoved(event: event)
            return event
        }
        
        // Add the main screen on startup.
        if let mouseScreen = NSScreen.mouse {
            if let trackedScreen = trackedScreenManager.append(screen: mouseScreen) {
                delegate?.accessibilityDeniedNotificationManager(self, didActivateScreen: trackedScreen)
            }
            lastScreenFrame = mouseScreen.frame
        }
    }
    
    func stop() {
        if let globalMouseMonitor = globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        
        if let localMouseMonitor = localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
    }

    private func handleMouseMoved(event: NSEvent) {
        if let mouseScreen = NSScreen.mouse {
            if !mouseScreen.frame.equalTo(lastScreenFrame) {
                if let trackedScreen = trackedScreenManager.append(screen: mouseScreen) {
                    delegate?.accessibilityDeniedNotificationManager(self, didActivateScreen: trackedScreen)
                }
                lastScreenFrame = mouseScreen.frame
            }
        }
    }
}

