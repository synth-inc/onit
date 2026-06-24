//
//  ScreenRecordingPermissionManager.swift
//  Onit
//
//  Created by Kévin Naudin on 06/25/2025.
//

import Combine
import Defaults
import Foundation
import ScreenCaptureKit

@MainActor
class ScreenRecordingPermissionManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = ScreenRecordingPermissionManager()
    
    // MARK: - Published Properties
    @Published private(set) var isScreenRecordingEnabled: Bool
    @Published private(set) var messageToShow: String?
    
    // MARK: - Private Init
    private init() {
        self.isScreenRecordingEnabled = CGPreflightScreenCaptureAccess()
    }
    
    // MARK: - Permission Status
    
    func hasScreenRecordingPermission() -> Bool {
        return CGPreflightScreenCaptureAccess()
    }
    
    func refreshPermissionStatus() {
        let currentStatus = hasScreenRecordingPermission()
        
        if currentStatus != isScreenRecordingEnabled {
            isScreenRecordingEnabled = currentStatus
        }
    }
    
    // MARK: - Permission Request

    /// Ensures screen recording permission is granted, throws if denied.
    /// No UI side effects - use requestScreenRecordingPermission() for UI flows.
    func ensurePermission() async throws {
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            throw ScreenRecordingError.permissionDenied("Screen recording permission denied. Please enable it in System Settings > Privacy & Security > Screen Recording")
        }
    }

    func requestScreenRecordingPermission() async -> Bool {
        // Use ScreenCaptureKit to trigger the system permission dialog
        do {
            _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        } catch {
            // Permission denied or not yet granted
            // Always open Settings on Screen Recording tab, especially if Settings is already open on another tab
            openScreenRecordingSettings()
            messageToShow = "Opening System Settings...\nPlease enable Screen Recording access for SideKick, then click 'Quit & Reopen' to apply the changes."
            Defaults[.screenRecordingPermissionAsked] = true
            return false
        }

        // On macOS 14+, SCShareableContent no longer throws when permission is denied — it returns
        // limited content instead. Check the actual permission status via CGPreflightScreenCaptureAccess.
        let granted = CGPreflightScreenCaptureAccess()
        isScreenRecordingEnabled = granted
        if !granted {
            openScreenRecordingSettings()
            messageToShow = "Opening System Settings...\nPlease enable Screen Recording access for SideKick, then click 'Quit & Reopen' to apply the changes."
            Defaults[.screenRecordingPermissionAsked] = true
        }
        return granted
    }
    
    func openScreenRecordingSettings() {
        let screenRecordingUrl: String

        if #available(macOS 26, *) {
            screenRecordingUrl = "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_ScreenCapture"
        } else {
            screenRecordingUrl = "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture"
        }

        if let url = URL(string: screenRecordingUrl) {
            NSWorkspace.shared.open(url)
        }
    }
}
