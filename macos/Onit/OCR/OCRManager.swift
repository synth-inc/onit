//
//  OCRManager.swift
//  Onit
//
//  Created by Kévin Naudin on 06/04/2025.
//

import Foundation
import ScreenCaptureKit

@globalActor
struct OCRActor {
    static let shared = OCRActorType()
}
actor OCRActorType {}

@OCRActor
class OCRManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = OCRManager()
    
    // MARK: - Private Properties
    
    private let windowCaptureOCR = WindowCaptureOCR()
    
    // MARK: - Private Initialization
    
    private init() {}
    
    // MARK: - Functions
    
    /// Extracts text from the specified app window and returns OCR observations and a CGImage screenshot.
    func extractTextFromApp(_ appName: String, appTitle: String? = nil, windowFrame: CGRect? = nil) async throws -> (observations: [OCRTextObservation], image: CGImage) {
        try await ensureScreenRecordingPermission()
        let (observations, image) = try await self.windowCaptureOCR.captureWindowAndExtractText(from: appName, appTitle: appTitle, windowFrame: windowFrame)
        return (observations, image)
    }
    
    /// Extracts a screenshot as a CGImage from the specified app window.
    func extractScreenshot(from appName: String, appTitle: String? = nil, windowFrame: CGRect? = nil) async throws -> CGImage {
        try await ensureScreenRecordingPermission()
        let screenshot = try await windowCaptureOCR.captureWindowScreenshot(from: appName, appTitle: appTitle, windowFrame: windowFrame)
        return screenshot
    }
    
    // MARK: - Private Functions
    
    private func ensureScreenRecordingPermission() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let _ = try await SCShareableContent.excludingDesktopWindows(
                        false,
                        onScreenWindowsOnly: true
                    )

                    continuation.resume()
                } catch {
                    DispatchQueue.main.async {
                        let granted = CGRequestScreenCaptureAccess()

                        if !granted {
                            continuation.resume(throwing: OCRError.permissionDenied("Screen recording permission was denied. Please enable screen recording for this app in System Settings > Privacy & Security > Screen Recording"))
                            return
                        }

                        Task.detached {
                            do {
                                let _ = try await SCShareableContent.excludingDesktopWindows(
                                    false,
                                    onScreenWindowsOnly: true
                                )
                                continuation.resume()
                            } catch {
                                continuation.resume(throwing: OCRError.permissionDenied("Screen recording permission is still not available after request. Please check System Settings > Privacy & Security > Screen Recording"))
                            }
                        }
                    }
                }
            }
        }
    }
}
