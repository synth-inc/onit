//
//  ScreenRecordingManager.swift
//  Onit
//
//  Created by Kévin Naudin on 09/17/2025.
//

import ApplicationServices
import AppKit
import Foundation
import ScreenCaptureKit

// MARK: - Errors

enum ScreenRecordingError: Error, LocalizedError {
    case windowNotFound(String)
    case captureError(String)
    case permissionDenied(String)

    var errorDescription: String? {
        switch self {
        case .windowNotFound(let appName):
            return "Window not found for application: \(appName)"
        case .captureError(let message):
            return "Capture error: \(message)"
        case .permissionDenied(let message):
            return "Permission denied: \(message)"
        }
    }
}

final class ScreenRecordingManager {

    // MARK: - Permission

    /// Ensures screen recording permission is granted, throws if denied.
    @MainActor
    static func ensurePermission() async throws {
        try await ScreenRecordingPermissionManager.shared.ensurePermission()
    }

    // MARK: - Screen Region Capture

    static func captureElementScreenshot(for element: AXUIElement) async -> CGImage? {
        guard let elementFrame = element.getFrame() else { return nil }

        return await captureScreenRegion(at: elementFrame)
    }

    static func captureScreenRegion(at rect: CGRect) async -> CGImage? {
        guard rect.width > 0 && rect.height > 0 else { return nil }

        // Use ScreenCaptureKit to avoid "recording your screen" popup
        return await captureScreenRegionWithScreenCaptureKit(at: rect, excludeOwnWindows: false)
    }

    /// Captures a screen region excluding our own app's windows using ScreenCaptureKit
    /// This avoids the "recording your screen" popup that CGWindowListCreateImage causes
    static func captureScreenRegionExcludingOwnWindows(at rect: CGRect) async -> CGImage? {
        guard rect.width > 0 && rect.height > 0 else { return nil }

        return await captureScreenRegionWithScreenCaptureKit(at: rect, excludeOwnWindows: true)
    }

    /// Internal implementation using ScreenCaptureKit
    private static func captureScreenRegionWithScreenCaptureKit(at rect: CGRect, excludeOwnWindows: Bool) async -> CGImage? {
        // Preflight before calling SCShareableContent — calling it without permission triggers
        // the macOS "record your screen" system dialog, which we never want as a side effect.
        guard CGPreflightScreenCaptureAccess() else {
            print("[ScreenRecordingManager] Screen recording permission not granted, skipping capture")
            return nil
        }
        do {
            // Get shareable content (displays and windows)
            let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            guard let primaryScreenFrame = NSScreen.primary?.frame else {
                print("[ScreenRecordingManager] Couldn't find primary screen")
                return nil
            }
            
            let globalCoordinatesRect = CGRect(x: rect.minX, y: primaryScreenFrame.height - rect.maxY, width: rect.width, height: rect.height)
            
            // Find the display that contains the rect
            guard let display = content.displays.first(where: { display in
                let displayFrame = CGRect(x: CGFloat(display.frame.origin.x),
                                          y: CGFloat(display.frame.origin.y), // As always, need to flip the coordinates.
                                          width: CGFloat(display.frame.width),
                                          height: CGFloat(display.frame.height))
                
                return displayFrame.intersects(globalCoordinatesRect)
            }) else {
                print("[ScreenRecordingManager] No display found containing rect: \(rect)")
                return nil
            }

            // Build list of windows to exclude (our own app's windows)
            var excludedWindows: [SCWindow] = []
            if excludeOwnWindows {
                let ourBundleID = Bundle.main.bundleIdentifier
                excludedWindows = content.windows.filter { window in
                    window.owningApplication?.bundleIdentifier == ourBundleID
                }
            }

            // Create content filter for the display, excluding our windows
            let filter: SCContentFilter
            if excludedWindows.isEmpty {
                filter = SCContentFilter(display: display, excludingWindows: [])
            } else {
                filter = SCContentFilter(display: display, excludingWindows: excludedWindows)
            }

            // Configure the capture
            let configuration = SCStreamConfiguration()

            // Request 1x scale to match the input rect dimensions
            // This avoids needing to downscale the result
            configuration.width = Int(display.width)
            configuration.height = Int(display.height)
            configuration.captureResolution = .nominal  // Use nominal (1x) resolution
            configuration.scalesToFit = false
            configuration.showsCursor = false
            configuration.pixelFormat = kCVPixelFormatType_32BGRA

            // Capture the full display
            let fullImage = try await SCScreenshotManager.captureImage(
                contentFilter: filter,
                configuration: configuration
            )

            // Calculate crop rect relative to the display
            // Both globalCoordinatesRect and displayFrame are in the same coordinate system now
            let displayFrame = display.frame

            let relativeX = globalCoordinatesRect.origin.x - CGFloat(displayFrame.origin.x)
            let relativeY = globalCoordinatesRect.origin.y - CGFloat(displayFrame.origin.y)

            let cropRect = CGRect(
                x: relativeX,
                y: relativeY,
                width: globalCoordinatesRect.width,
                height: globalCoordinatesRect.height
            )

            // Ensure crop rect is within bounds
            let validCropRect = cropRect.intersection(CGRect(x: 0, y: 0, width: fullImage.width, height: fullImage.height))

            guard validCropRect.width > 0 && validCropRect.height > 0 else {
                print("[ScreenRecordingManager] Invalid crop rect: \(cropRect)")
                return nil
            }

            // Crop to the desired region
            return fullImage.cropping(to: validCropRect)

        } catch {
            print("[ScreenRecordingManager] ScreenCaptureKit capture failed: \(error)")
            return nil
        }
    }

    /// Captures a screenshot of an element by capturing its parent window and cropping
    static func captureWindowElement(for element: AXUIElement) async -> CGImage? {
        guard let appName = element.appName(),
              let elementFrame = element.getFrame(),
              elementFrame.width > 0,
              elementFrame.height > 0 else {
            log.error("Cannot capture screenshot: missing app name or invalid frame")
            return nil
        }
        
        do {
            let fullScreenshot = try await captureWindowScreenshot(from: appName)
            
            guard let resizedScreenshot = resizeScreenshotToWindowSize(fullScreenshot, element: element) else {
                log.error("Failed to resize screenshot to window size")
                return nil
            }
            
            guard let croppedScreenshot = cropScreenshot(resizedScreenshot, to: elementFrame, element: element) else {
                log.error("Failed to crop screenshot to element frame")
                return nil
            }
            
            return croppedScreenshot
        } catch {
            log.error("Failed to capture screenshot for element in \(appName): \(error.localizedDescription)")
            return nil
        }
    }

    /// Legacy name for compatibility - use captureWindowElement instead
    static func captureElementScreenshotOld(for element: AXUIElement) async -> CGImage? {
        return await captureWindowElement(for: element)
    }
    
    private static func resizeScreenshotToWindowSize(_ image: CGImage, element: AXUIElement) -> CGImage? {
        guard let windowFrame = getWindowFrame(for: element) else {
            log.error("Cannot get window frame for resizing")
            return nil
        }
        
        let targetWidth = Int(windowFrame.width)
        let targetHeight = Int(windowFrame.height)
        
        guard let context = CGContext(
            data: nil,
            width: targetWidth,
            height: targetHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            log.error("Failed to create graphics context for resizing")
            return nil
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        
        guard let resizedImage = context.makeImage() else {
            log.error("Failed to create resized image")
            return nil
        }
        
        return resizedImage
    }
    
    private static func cropScreenshot(_ image: CGImage, to elementFrame: CGRect, element: AXUIElement) -> CGImage? {
        guard let windowFrame = getWindowFrame(for: element) else {
            log.error("Cannot get window frame for cropping")
            return nil
        }
        
        let relativeX = elementFrame.origin.x - windowFrame.origin.x
        let relativeY = elementFrame.origin.y - windowFrame.origin.y
        let cropRect = CGRect(
            x: max(0, relativeX),
            y: max(0, relativeY),
            width: min(elementFrame.width, CGFloat(image.width) - max(0, relativeX)),
            height: min(elementFrame.height, CGFloat(image.height) - max(0, relativeY))
        )
        
        guard cropRect.width > 0 && cropRect.height > 0 else {
            log.error("Invalid crop rectangle: \(cropRect)")
            return nil
        }
        
        guard let croppedImage = image.cropping(to: cropRect) else {
            log.error("Failed to crop image with rect: \(cropRect)")
            return nil
        }
        
        return croppedImage
    }
    
    private static func getWindowFrame(for element: AXUIElement) -> CGRect? {
        guard let pid = element.pid(),
              let mainWindow = pid.firstMainWindow,
              let frame = mainWindow.getFrame() else {
            let appName = element.appName() ?? "Unknown"
            log.error("Cannot get main window frame for \(appName)")
            return nil
        }
        
        return frame
    }
    
    // MARK: - Window-based Capture

    /// Captures a screenshot of a specific app's window
    static func captureWindowScreenshot(from appName: String, appTitle: String? = nil, windowFrame: CGRect? = nil) async throws -> CGImage {
        let window = try await findWindow(for: appName, targetAppTitle: appTitle, targetWindowFrame: windowFrame)
        return try await captureWindow(window)
    }

    /// Finds the best matching window for an app
    private static func findWindow(for appName: String, targetAppTitle: String? = nil, targetWindowFrame: CGRect? = nil) async throws -> SCWindow {
        let shareableContent = try await SCShareableContent.excludingDesktopWindows(
            false,
            onScreenWindowsOnly: true
        )

        // Filter windows by app name first
        let appWindows = shareableContent.windows.filter { window in
            guard let app = window.owningApplication else { return false }
            return app.applicationName.lowercased().contains(appName.lowercased())
        }

        var bestMatch: SCWindow?
        var bestScore = 0

        // Evaluate all candidate windows and find the best match
        for window in appWindows {
            var score = 0

            let curWindowTitle = window.title ?? ""
            let curWindowFrame = window.frame

            // Score based on title matching
            if let targetTitle = targetAppTitle, !targetTitle.isEmpty {
                if curWindowTitle.lowercased() == targetTitle.lowercased() {
                    score += 100
                } else if curWindowTitle.lowercased().contains(targetTitle.lowercased()) {
                    score += 75
                } else if targetTitle.lowercased().contains(curWindowTitle.lowercased()) && !curWindowTitle.isEmpty {
                    score += 50
                }
            } else {
                // If no target title provided, prefer windows with non-empty titles
                if !curWindowTitle.isEmpty {
                    score += 25
                }
            }

            if let targetFrame = targetWindowFrame {
                let frameDifference = calculateFrameDifference(targetFrame, curWindowFrame)
                if frameDifference < 10 {
                    score += 100
                } else if frameDifference < 50 {
                    score += 75
                } else if frameDifference < 200 {
                    score += 25
                }
            }

            // Prefer larger windows (more likely to be main windows)
            let windowArea = curWindowFrame.width * curWindowFrame.height
            if windowArea > 10000 {
                score += 10
            } else if windowArea > 1000 {
                score += 5
            }

            // Prefer windows that are reasonably positioned (not off-screen)
            if curWindowFrame.origin.x >= -100 && curWindowFrame.origin.y >= -100 {
                score += 5
            }

            if score > bestScore {
                bestScore = score
                bestMatch = window
            }
        }

        guard let selectedWindow = bestMatch else {
            throw ScreenRecordingError.windowNotFound(appName)
        }

        return selectedWindow
    }

    private static func calculateFrameDifference(_ frame1: CGRect, _ frame2: CGRect) -> Double {
        let xDiff = abs(frame1.origin.x - frame2.origin.x)
        let yDiff = abs(frame1.origin.y - frame2.origin.y)
        let widthDiff = abs(frame1.size.width - frame2.size.width)
        let heightDiff = abs(frame1.size.height - frame2.size.height)

        return Double(xDiff + yDiff + (widthDiff * 0.5) + (heightDiff * 0.5))
    }

    /// Captures a specific window using ScreenCaptureKit
    private static func captureWindow(_ window: SCWindow) async throws -> CGImage {
        let filter = SCContentFilter(desktopIndependentWindow: window)
        let configuration = SCStreamConfiguration()

        let scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
        let captureWidth = Int(window.frame.width * scaleFactor)
        let captureHeight = Int(window.frame.height * scaleFactor)

        configuration.width = captureWidth
        configuration.height = captureHeight
        configuration.captureResolution = .best
        configuration.scalesToFit = false
        configuration.preservesAspectRatio = true
        configuration.showsCursor = false
        configuration.ignoreShadowsDisplay = true
        configuration.ignoreShadowsSingleWindow = true
        configuration.capturesShadowsOnly = false
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.backgroundColor = CGColor.clear

        let cgImage = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        return cgImage
    }
}
