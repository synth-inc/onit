//
//  OCRManager.swift
//  Onit
//
//  Created by Kévin Naudin on 06/04/2025.
//

import CoreGraphics
import Foundation

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
        try await ScreenRecordingManager.ensurePermission()
        let (observations, image) = try await self.windowCaptureOCR.captureWindowAndExtractText(from: appName, appTitle: appTitle, windowFrame: windowFrame)
        return (observations, image)
    }
    
    /// Extracts a screenshot as a CGImage from the specified app window.
    func extractScreenshot(from appName: String, appTitle: String? = nil, windowFrame: CGRect? = nil) async throws -> CGImage {
        try await ScreenRecordingManager.ensurePermission()
        return try await ScreenRecordingManager.captureWindowScreenshot(from: appName, appTitle: appTitle, windowFrame: windowFrame)
    }
}
