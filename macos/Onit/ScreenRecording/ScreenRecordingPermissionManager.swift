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
    @Published private(set) var isRequestingPermission: Bool = false
    
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
        isRequestingPermission = true
        
        defer {
            isRequestingPermission = false
            Defaults[.screenRecordingPermissionAsked] = true
        }
        
        let wasAlreadyRequested = Defaults[.screenRecordingPermissionAsked]
        let requestResult = CGRequestScreenCaptureAccess()
        
        if requestResult {
            isScreenRecordingEnabled = true
            return true
        }
        
        if wasAlreadyRequested {
            openScreenRecordingSettings()
        }
        
        return false
    }
    
    private func openScreenRecordingSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!
        NSWorkspace.shared.open(url)
    }
}
