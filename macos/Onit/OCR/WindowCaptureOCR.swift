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
    
    /// Captures the window and extracts text, returning OCR observations and a CGImage.
    func captureWindowAndExtractText(from appName: String, appTitle: String? = nil, windowFrame: CGRect? = nil) async throws -> (observations: [OCRTextObservation], image: CGImage) {
        print("captureWindow - for app: \(appName), title: \(appTitle ?? "nil"), frame: \(windowFrame?.debugDescription ?? "nil")")
        let window = try await findWindow(for: appName, targetAppTitle: appTitle, targetWindowFrame: windowFrame)
        let image = try await captureWindow(window: window)
        let observations = try await performOCR(on: image)
        return (observations, image)
    }
    
    /// Captures a screenshot as a CGImage from the specified app window.
    func captureWindowScreenshot(from appName: String, appTitle: String? = nil, windowFrame: CGRect? = nil) async throws -> CGImage {
        let window = try await findWindow(for: appName, targetAppTitle: appTitle, targetWindowFrame: windowFrame)
        return try await captureWindow(window: window)
    }
    
    // MARK: - Private Functions
    
    private func findWindow(for appName: String, targetAppTitle: String? = nil, targetWindowFrame: CGRect? = nil) async throws -> SCWindow {
        let shareableContent = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )
        
        print("findWindow - Target app: '\(appName)', title: '\(targetAppTitle ?? "nil")', frame: \(targetWindowFrame?.debugDescription ?? "nil")")
        
        // Filter windows by app name first
        let appWindows = shareableContent.windows.filter { window in
            guard let app = window.owningApplication else { return false }
            return app.applicationName.lowercased().contains(appName.lowercased())
        }
        
        print("findWindow - Found \(appWindows.count) windows for app '\(appName)'")
        
        var bestMatch: SCWindow?
        var bestScore = 0
        
        // Evaluate all candidate windows and find the best match
        for (index, window) in appWindows.enumerated() {
            var score = 0
            var matchDetails: [String] = []
            
            let curWindowTitle = window.title ?? ""
            let curWindowFrame = window.frame
            
            print("findWindow - Candidate \(index + 1): title: '\(curWindowTitle)', frame: \(curWindowFrame)")
            
            // Score based on title matching
            if let targetTitle = targetAppTitle, !targetTitle.isEmpty {
                if curWindowTitle.lowercased() == targetTitle.lowercased() {
                    score += 100
                    matchDetails.append("exact title match")
                } else if curWindowTitle.lowercased().contains(targetTitle.lowercased()) {
                    score += 75
                    matchDetails.append("partial title match")
                } else if targetTitle.lowercased().contains(curWindowTitle.lowercased()) && !curWindowTitle.isEmpty {
                    score += 50
                    matchDetails.append("title contained in target")
                }
            } else {
                // If no target title provided, prefer windows with non-empty titles
                if !curWindowTitle.isEmpty {
                    score += 25
                    matchDetails.append("has title")
                }
            }
            if let targetFrame = targetWindowFrame {
                let frameDifference = calculateFrameDifference(targetFrame, curWindowFrame)
                if frameDifference < 10 {
                    score += 100
                    matchDetails.append("exact frame match")
                } else if frameDifference < 50 {
                    score += 75
                    matchDetails.append("close frame match")
                } else if frameDifference < 200 {
                    score += 25
                    matchDetails.append("approximate frame match")
                }
            }
            
            // Prefer larger windows (more likely to be main windows)
            let windowArea = curWindowFrame.width * curWindowFrame.height
            if windowArea > 10000 {
                score += 10
                matchDetails.append("large window")
            } else if windowArea > 1000 {
                score += 5
                matchDetails.append("medium window")
            }
            
            // Prefer windows that are reasonably positioned (not off-screen)
            if curWindowFrame.origin.x >= -100 && curWindowFrame.origin.y >= -100 {
                score += 5
                matchDetails.append("on-screen position")
            }
            
            print("findWindow - Candidate \(index + 1) score: \(score) (\(matchDetails.joined(separator: ", ")))")
            
            if score > bestScore {
                bestScore = score
                bestMatch = window
                print("findWindow - New best match with score \(score)")
            }
        }
        
        guard let selectedWindow = bestMatch else {
            print("findWindow - No suitable window found for app '\(appName)'")
            throw OCRError.windowNotFound(appName)
        }
        
        print("findWindow - Selected window: title: '\(selectedWindow.title ?? "")', frame: \(selectedWindow.frame), final score: \(bestScore)")
        return selectedWindow
    }
    
    private func calculateFrameDifference(_ frame1: CGRect, _ frame2: CGRect) -> Double {
        let xDiff = abs(frame1.origin.x - frame2.origin.x)
        let yDiff = abs(frame1.origin.y - frame2.origin.y)
        let widthDiff = abs(frame1.size.width - frame2.size.width)
        let heightDiff = abs(frame1.size.height - frame2.size.height)
        
        // Calculate a weighted difference score
        return Double(xDiff + yDiff + (widthDiff * 0.5) + (heightDiff * 0.5))
    }
    
    private func captureWindow(window: SCWindow) async throws -> CGImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()
        
        print("captureWindow - Window frame width: \(window.frame.width)")
        print("captureWindow - Window frame height: \(window.frame.height)")
        
        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
        let captureWidth = Int(window.frame.width * scaleFactor)
        let captureHeight = Int(window.frame.height * scaleFactor)
        
        configuration.width = captureWidth
        configuration.height = captureHeight
        configuration.captureResolution = .best
        configuration.scalesToFit = false
        configuration.preservesAspectRatio = true
        configuration.showsCursor = false
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.backgroundColor = CGColor.clear
        
        let cgImage = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        return cgImage
    }
    
    private func performOCR(on image: CGImage) async throws -> [OCRTextObservation] {
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
            request.usesLanguageCorrection = true
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
                    .foregroundColor: NSColor.white,
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
