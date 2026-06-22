//
//  FeatureDisableWindowManager.swift
//  Onit
//
//  Created by Loyd Kim on 10/20/25.
//

import AppKit

@MainActor
final class FeatureDisableWindowManager: NSObject, NSWindowDelegate {
    // MARK: - Singleton

    static let shared = FeatureDisableWindowManager()

    // MARK: - Private Variables

    @ObservationIgnored
    private var window: FeatureDisableWindow? = nil

    // MARK: -  Public Functions

    func createWindow(
        foregroundWindow: TrackedWindow? = nil,
        disableType: FeatureDisableWindowDisableType = .expirationTime
    ) {
        self.closeWindow()

        self.window = FeatureDisableWindow(
            foregroundWindow: foregroundWindow,
            disableType: disableType
        )

        guard let window = self.window else {
            return
        }

        window.isReleasedWhenClosed = false
        window.delegate = self
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func closeWindow() {
        if let window = self.window {
            window.close()
        }
    }

    // MARK: - NSWindowDelegate Protocol Conformance

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? FeatureDisableWindow,
           window === self.window
        else {
            return
        }

        window.cleanupObservers()
        window.delegate = nil
        self.window = nil
    }
}
