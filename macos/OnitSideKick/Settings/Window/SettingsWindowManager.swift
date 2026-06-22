//
//  SettingsWindowManager.swift
//  Onit
//
//  Created by Loyd Kim on 9/2/25.
//

import AppKit
import Defaults

@MainActor
@Observable
final class SettingsWindowManager: NSObject, NSWindowDelegate {
    // MARK: - Singleton
    
    static let shared = SettingsWindowManager()
    
    // MARK: - Private Variables
    
    @ObservationIgnored
    private var window: SettingsWindow? = nil
    
    // MARK: - Private Functions
    
    private func showExistingWindow(_ window: SettingsWindow) {
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    private func createWindow() {
        self.window = SettingsWindow()
        
        guard let window = self.window else { return }
        
        window.delegate = self
        window.isReleasedWhenClosed = false
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }
    
    // MARK: -  Public Functions
    
    func showWindow(page: SettingsPage = .general) {
        Defaults[.settingsPage] = page
        
        if let existingWindow = self.window {
            self.showExistingWindow(existingWindow)
        } else {
            self.createWindow()
        }
    }
    
    func closeWindow() {
        if let window = self.window {
            window.close()
        }
    }
    
    // MARK: - NSWindowDelegate Protocol Conformance
    
    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? SettingsWindow,
           window === self.window
        else {
            return
        }
        
        window.cleanupObservers()
        window.delegate = nil
        self.window = nil
    }
}
