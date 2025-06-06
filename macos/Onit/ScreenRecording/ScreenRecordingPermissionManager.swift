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
    
    func requestScreenRecordingPermission() -> Bool {
        let wasAlreadyRequested = Defaults[.screenRecordingPermissionAsked]
        let requestResult = CGRequestScreenCaptureAccess()
        
        if requestResult {
            isScreenRecordingEnabled = true
            return true
        }
        
        if wasAlreadyRequested {
            openScreenRecordingSettings()
            messageToShow = "Opening System Settings...\nPlease enable Screen Recording access for Onit, then click 'Quit & Reopen' to apply the changes."
        } else {
			messageToShow = "Opening Screen Recording permission alert...\nOpen System Settings, enable Screen Recording for Onit, then click 'Quit & Reopen' to restart the app with the new permission."
		}
        
        Defaults[.screenRecordingPermissionAsked] = true
        
        return false
    }
    
    private func openScreenRecordingSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}
