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
    
    func captureWindowAndExtractText(from appName: String) async throws -> (observations: [OCRTextObservation], image: NSImage) {
        let window = try await findWindow(for: appName)
        let image = try await captureWindow(window: window)
        let observations = try await performOCR(on: image)
        return (observations, image)
    }
    
    func captureWindowScreenshot(from appName: String) async throws -> NSImage {
        let window = try await findWindow(for: appName)
        return try await captureWindow(window: window)
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
        
        print("captureWindow - Window frame width: \(window.frame.width)")
        print("captureWindow - Window frame height: \(window.frame.height)")
        
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
        let captureWidth = Int(window.frame.width * scaleFactor)
        let captureHeight = Int(window.frame.height * scaleFactor)
        
        configuration.width = max(captureWidth, Int(window.frame.width))
        configuration.height = max(captureHeight, Int(window.frame.height))
        configuration.captureResolution = .best
        configuration.scalesToFit = false
        configuration.showsCursor = false
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.backgroundColor = CGColor.clear
        
        print("captureWindow - Capture size: \(configuration.width) x \(configuration.height)")
        
        let cgImage = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        
        let imageSize = NSSize(width: window.frame.width, height: window.frame.height)
        let nsImage = NSImage(cgImage: cgImage, size: imageSize)
        
        print("captureWindow - Final image size: \(nsImage.size.width) x \(nsImage.size.height)")
        print("captureWindow - CGImage size: \(cgImage.width) x \(cgImage.height)")
        
        return nsImage
    }
    
    private func performOCR(on image: NSImage) async throws -> [OCRTextObservation] {
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
                
                let results = observations.compactMap { observation -> OCRTextObservation? in
                    guard let candidate = observation.topCandidates(1).first else { return nil }
                    
                    // Convert normalized coordinates to image coordinates
                    let bounds = VNImageRectForNormalizedRect(observation.boundingBox,
                                                            Int(image.size.width),
                                                            Int(image.size.height))
                    
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
    
    func createDebugImage(original: NSImage, failedObservations: [OCRTextObservation]) -> NSImage {
        let debugImage = NSImage(size: original.size)
        
        debugImage.lockFocus()
        
        // Draw original image
        original.draw(in: NSRect(origin: .zero, size: original.size))
        
        // Set up red highlight
        NSColor.red.withAlphaComponent(0.3).set()
        
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
    
    func createAccessibilityDebugImage(original: NSImage, accessibilityBoundingBoxes: [TextBoundingBox]) -> NSImage {
        let debugImage = NSImage(size: original.size)
        
        debugImage.lockFocus()
        
        // Draw original image
        original.draw(in: NSRect(origin: .zero, size: original.size))
        
        // Draw rectangles around accessibility bounding boxes
        for textBox in accessibilityBoundingBoxes {
            let convertedRect = convertAccessibilityCoordinates(textBox.boundingBox, imageSize: original.size)
            
            let path = NSBezierPath(rect: convertedRect)
            path.lineWidth = 2
            NSColor.green.withAlphaComponent(0.8).setStroke()
            path.stroke()
            
            if !textBox.text.isEmpty {
                let font = NSFont.systemFont(ofSize: 10)
                let attributes: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.white,
                    .backgroundColor: NSColor.green.withAlphaComponent(0.8)
                ]
                
                let labelText = textBox.text.count > 30 ? String(textBox.text.prefix(30)) + "..." : textBox.text
                let attributedString = NSAttributedString(string: labelText, attributes: attributes)
                
                let labelRect = NSRect(
                    x: convertedRect.origin.x,
                    y: convertedRect.origin.y - attributedString.size().height - 2, 
                    width: min(attributedString.size().width + 4, original.size.width - convertedRect.origin.x),
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
