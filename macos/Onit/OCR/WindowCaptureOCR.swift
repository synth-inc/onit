//
//  WindowCaptureOCR.swift
//  Onit
//
//  Created by Kévin Naudin on 06/04/2025.
//

import AppKit
import Foundation
import ScreenCaptureKit
@preconcurrency import Vision

final class WindowCaptureOCR: Sendable {
    
    // MARK: - Properties
    
    private let visionQueue = DispatchQueue(label: "com.onit.vision", qos: .userInitiated)
    
    // MARK: - Functions
    
    func captureWindowAndExtractText(from appName: String) async throws -> String {
        let window = try await findWindow(for: appName)
        let image = try await captureWindow(window: window)
		
        return try await performOCR(on: image)
    }
    
    // MARK: - Private Functions
    
    private func findWindow(for appName: String) async throws -> SCWindow {
        let shareableContent = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        
        guard let window = shareableContent.windows.first(where: { window in
            guard let app = window.owningApplication else { return false }
            return app.applicationName.lowercased().contains(appName.lowercased())
        }) else {
            throw OCRError.windowNotFound(appName)
        }
        
        return window
    }
    
    private func captureWindow(window: SCWindow) async throws -> NSImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()

        configuration.width = Int(window.frame.width)
        configuration.height = Int(window.frame.height)
        configuration.captureResolution = .best
        configuration.scalesToFit = false
        configuration.showsCursor = false
        
        let cgImage = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        let nsImage = NSImage(cgImage: cgImage, size: window.frame.size)
		
        return nsImage
    }
    
    private func performOCR(on image: NSImage) async throws -> String {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw OCRError.ocrError("Failed to convert image to CGImage")
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.ocrError(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.ocrError("No text observations found"))
                    return
                }
                
                let extractedText = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }.joined(separator: "\n")
                
                continuation.resume(returning: extractedText)
            }
            
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            
            visionQueue.async {
                let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.ocrError(error.localizedDescription))
                }
            }
        }
    }
}

// MARK: - Error Types

enum OCRError: Error, LocalizedError {
    case windowNotFound(String)
    case captureError(String)
    case ocrError(String)
    case permissionDenied(String)
    
    var errorDescription: String? {
        switch self {
        case .windowNotFound(let appName):
            return "Window not found for application: \(appName)"
        case .captureError(let message):
            return "Capture error: \(message)"
        case .ocrError(let message):
            return "OCR error: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        }
    }
}
