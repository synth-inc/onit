//
//  WindowCaptureOCR.swift
//  Onit
//
//  Created by Kévin Naudin on 06/04/2025.
//

import AppKit
import Foundation
@preconcurrency import Vision

final class WindowCaptureOCR: Sendable {
    
    // MARK: - Properties
    
    private let visionQueue = DispatchQueue(label: "com.onit.vision", qos: .userInitiated)
    
    // MARK: - Functions
    
    /// Captures the window and extracts text, returning OCR observations and a CGImage.
    func captureWindowAndExtractText(from appName: String, appTitle: String? = nil, windowFrame: CGRect? = nil, usesLanguageCorrection: Bool = true) async throws -> (observations: [OCRTextObservation], image: CGImage) {
        let image = try await ScreenRecordingManager.captureWindowScreenshot(from: appName, appTitle: appTitle, windowFrame: windowFrame)
        let observations = try await performOCR(on: image, usesLanguageCorrection: usesLanguageCorrection)
        return (observations, image)
    }

    /// OCR an already-loaded image (e.g. a saved screenshot). Used by the
    /// format-matcher history back-test to re-mine on-screen terms offline.
    func recognizeText(in image: CGImage, usesLanguageCorrection: Bool = true) async throws -> [OCRTextObservation] {
        try await performOCR(on: image, usesLanguageCorrection: usesLanguageCorrection)
    }

    // MARK: - Private Functions

    /// - Parameter usesLanguageCorrection: keep `true` for human-readable OCR;
    ///   pass `false` for term mining so Vision doesn't normalise jargon/proper
    ///   nouns ("Posthog" → "Post hog", "Onit" → "on it").
    private func performOCR(on image: CGImage, usesLanguageCorrection: Bool = true) async throws -> [OCRTextObservation] {
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
                let results = observations.compactMap { observation -> OCRTextObservation? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    let bounds = VNImageRectForNormalizedRect(observation.boundingBox,
                                                            image.width,
                                                            image.height)
                    
                    return OCRTextObservation(
                        text: candidate.string,
                        bounds: bounds,
                        confidence: candidate.confidence,
                        isFoundInAccessibility: false,
                        percentageMatched: 0
                    )
                }
                continuation.resume(returning: results)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = usesLanguageCorrection
            visionQueue.async {
                let handler = VNImageRequestHandler(cgImage: image, options: [:])
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: OCRError.ocrError(error.localizedDescription))
                }
            }
        }
    }
    
    func createDebugImage(original: CGImage, failedObservations: [OCRTextObservation]) -> NSImage {
        let nsImage = NSImage(cgImage: original, size: NSSize(width: original.width, height: original.height))
        let debugImage = NSImage(size: nsImage.size)
        
        debugImage.lockFocus()
        
        // Draw original image
        nsImage.draw(in: NSRect(origin: .zero, size: nsImage.size))
        
        // Set up red highlight
        NSColor.red500.withAlphaComponent(0.3).set()
        
        // Draw rectangles around failed observations
        for observation in failedObservations {
            let path = NSBezierPath(rect: observation.bounds)
            path.lineWidth = 2
            path.stroke()
            path.fill()
        }
        
        debugImage.unlockFocus()
        
        return debugImage
    }
    
    func createAccessibilityDebugImage(original: CGImage, accessibilityBoundingBoxes: [TextBoundingBox]) -> NSImage {
        let nsImage = NSImage(cgImage: original, size: NSSize(width: original.width, height: original.height))
        let debugImage = NSImage(size: nsImage.size)
        debugImage.lockFocus()
        
        // Draw original image
        nsImage.draw(in: NSRect(origin: .zero, size: nsImage.size))
        
        // Draw rectangles around accessibility bounding boxes
        for textBox in accessibilityBoundingBoxes {
            let convertedRect = convertAccessibilityCoordinates(textBox.boundingBox, imageSize: nsImage.size)
            
            let path = NSBezierPath(rect: convertedRect)
            path.lineWidth = 2
            NSColor.green.withAlphaComponent(0.8).setStroke()
            path.stroke()
            
            if !textBox.text.isEmpty {
                let font = NSFont.systemFont(ofSize: 10)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.S_0,
                    .backgroundColor: NSColor.green.withAlphaComponent(0.8)
                ]
                
                let labelText = textBox.text.count > 30 ? String(textBox.text.prefix(30)) + "..." : textBox.text
                let attributedString = NSAttributedString(string: labelText, attributes: attributes)
                
                let labelRect = NSRect(
                    x: convertedRect.origin.x,
                    y: convertedRect.origin.y - attributedString.size().height - 2,
                    width: min(attributedString.size().width + 4, nsImage.size.width - convertedRect.origin.x),
                    height: attributedString.size().height + 2
                )
                
                attributedString.draw(in: labelRect)
            }
        }
        
        debugImage.unlockFocus()
        
        return debugImage
    }
    
    private func convertAccessibilityCoordinates(_ accessibilityRect: CGRect, imageSize: NSSize) -> CGRect {
        let x = max(0, min(accessibilityRect.origin.x, imageSize.width - 1))
        let width = min(accessibilityRect.size.width, imageSize.width - x)
        let height = min(accessibilityRect.size.height, imageSize.height)
        
        let flippedY = imageSize.height - accessibilityRect.origin.y - accessibilityRect.size.height
        let y = max(0, min(flippedY, imageSize.height - 1))
        
        return CGRect(x: x, y: y, width: max(1, width), height: max(1, height))
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
