//
//  OCRManager.swift
//  Onit
//
//  Created by Kévin Naudin on 06/04/2025.
//

import Foundation
import Combine
import ScreenCaptureKit

@MainActor
class OCRManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = OCRManager()
    
    // MARK: - Private Properties
    
    private let windowCaptureOCR = WindowCaptureOCR()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Private Initialization
    
    private init() {}
    
    // MARK: - Functions
    
    func extractTextFromApp(_ appName: String) async throws -> (observations: [OCRTextObservation], image: NSImage) {
        try await ensureScreenRecordingPermission()
        
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let (observations, image) = try await self.windowCaptureOCR.captureWindowAndExtractText(from: appName)
                    continuation.resume(returning: (observations, image))
                } catch {
                    let ocrError = error as? OCRError ?? .captureError(error.localizedDescription)
                    continuation.resume(throwing: ocrError)
                }
            }
        }
    }
    
    func extractScreenshot(from appName: String) async throws -> NSImage {
        try await ensureScreenRecordingPermission()
        
        do {
            return try await withCheckedThrowingContinuation { continuation in
                Task.detached {
                    do {
                        let windowCaptureOCR = WindowCaptureOCR()
                        let screenshot = try await windowCaptureOCR.captureWindowScreenshot(from: appName)
                        continuation.resume(returning: screenshot)
                    } catch {
                        let ocrError = error as? OCRError ?? .captureError(error.localizedDescription)
                        continuation.resume(throwing: ocrError)
                    }
                }
            }
        } catch {
            let ocrError = error as? OCRError ?? .captureError(error.localizedDescription)
            throw ocrError
        }
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
