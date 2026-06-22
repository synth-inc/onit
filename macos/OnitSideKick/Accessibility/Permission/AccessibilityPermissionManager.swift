//
//  AccessibilityPermissionManager.swift
//  Onit
//
//  Created by Kévin Naudin on 16/01/2025.
//

@preconcurrency import ApplicationServices.HIServices.AXUIElement
import AppKit

/// Helper for requesting Accessibility's Permission
///
/// The `@preconcurrency` annotation is used because of `kAXTrustedCheckOptionPrompt` usage.
@MainActor
class AccessibilityPermissionManager: ObservableObject {

    // MARK: - Singleton instance

    static let shared = AccessibilityPermissionManager()

    // MARK: - Properties

    /** Get the actual state of permission. True means trusted, otherwise it's false */
    static var isProcessTrusted: Bool { AXIsProcessTrusted() }

    /** Optional timer to launch if permission is not trusted */
    private var processTrustedTimer: Timer?

    /** Get the state of permission managed by the `Timer` */
    private var isProcessTrustedFromTimer: Bool?

    @Published var accessibilityPermissionStatus: AccessibilityPermissionStatus = .notDetermined

    // MARK: - Initializers

    private init() { }

    // MARK: - Functions
    
    func configure() {
        processTrustedTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkProcessTrusted()
            }
        }
    }

    /**
     * Requests accessibility permissions if they are not already granted.
     *
     * This function monitors whether the application has the required accessibility permissions,
     * accessible through **System Preferences > Security & Privacy > Accessibility**.
     */
    func requestPermission() {
        guard !AccessibilityPermissionManager.isProcessTrusted else {
            return
        }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary

        AXIsProcessTrustedWithOptions(options)
    }
    
    func openAccessibilitySettingsWindow() {
        let accessibilityUrl: String
        
        if #available(macOS 26, *) {
            accessibilityUrl = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility"
        } else {
            accessibilityUrl = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        }

        if let url = URL(string: accessibilityUrl) {
            NSWorkspace.shared.open(url)
        }
    }

    // MARK: - Private

    /** Timer callback method */
    private func checkProcessTrusted() {
        let isProcessTrusted = AccessibilityPermissionManager.isProcessTrusted

        if isProcessTrustedFromTimer != isProcessTrusted {
            isProcessTrustedFromTimer = isProcessTrusted

            if isProcessTrusted {
                accessibilityPermissionStatus = .granted
            } else {
                accessibilityPermissionStatus = .denied
            }
        }
    }
    
    // MARK: - Cleanup
    
    func cleanup() {
        processTrustedTimer?.invalidate()
        processTrustedTimer = nil
    }
}
