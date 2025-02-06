//
//  AccessibilityPermissionManager.swift
//  Onit
//
//  Created by Kévin Naudin on 16/01/2025.
//

@preconcurrency import ApplicationServices.HIServices.AXUIElement

/// Helper for requesting Accessibility's Permission
///
/// The `@preconcurrency` annotation is used because of `kAXTrustedCheckOptionPrompt` usage.
@MainActor
class AccessibilityPermissionManager {

    // MARK: - Singleton instance

    static let shared = AccessibilityPermissionManager()

    // MARK: - Properties

    /** Get the actual state of permission. True means trusted, otherwise it's false */
    static var isProcessTrusted: Bool { AXIsProcessTrusted() }

    /** Optional timer to launch if permission is not trusted */
    private var processTrustedTimer: Timer?

    /** Get the state of permission managed by the `Timer` */
    private var isProcessTrustedFromTimer: Bool?

    /** Reference to `OnitModel` used to update the `accessibilityPermissionStatus` property */
    private var model: OnitModel?

    // MARK: - Initializers

    private init() {}

    // MARK: - Functions

    func setModel(_ model: OnitModel) {
        self.model = model
    }

    /** Start the accessibility permission listener */
    func startListeningPermission() {
        processTrustedTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(checkProcessTrusted),
            userInfo: nil,
            repeats: true)
    }

    /** Stop the accessibility permission listener */
    func stopListeningPermission() {
        processTrustedTimer?.invalidate()
        processTrustedTimer = nil
    }

    /**
     * Requests accessibility permissions if they are not already granted.
     *
     * This function monitors whether the application has the required accessibility permissions,
     * accessible through **System Preferences > Security & Privacy > Accessibility**.
     */
    func requestPermission() {
        guard !AccessibilityPermissionManager.isProcessTrusted else { return }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary

        AXIsProcessTrustedWithOptions(options)
    }

    // MARK: - Obj-c Functions

    /** Timer callback method */
    @objc private func checkProcessTrusted() {
        let isProcessTrusted = AccessibilityPermissionManager.isProcessTrusted

        if isProcessTrustedFromTimer != isProcessTrusted {
            isProcessTrustedFromTimer = isProcessTrusted

            if isProcessTrusted {
                model?.accessibilityPermissionStatus = .granted
            } else {
                model?.accessibilityPermissionStatus = .denied
            }
        }
    }
}
