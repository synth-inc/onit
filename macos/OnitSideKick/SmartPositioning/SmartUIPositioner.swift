//
//  SmartUIPositioner.swift
//  Onit
//
//  Shared service for finding optimal UI positions based on screen content complexity.
//  Uses GPU-accelerated image analysis to find empty/low-complexity areas.
//

import AppKit
import CoreGraphics
import CoreVideo
import Defaults
import ImageIO
import UniformTypeIdentifiers

/// Configuration for UI positioning
struct UIPositioningConfig {
    /// Size of the UI element to position
    let uiSize: CGSize

    /// Search padding in X direction (left and right of anchor bounds)
    let searchPaddingX: CGFloat

    /// Search padding in Y direction (above and below anchor bounds)
    let searchPaddingY: CGFloat

    /// Whether to use GPU-based complexity analysis (slower but smarter)
    let useComplexityAnalysis: Bool

    /// Bias toward the left side (0.0 = no bias, higher = stronger left preference)
    let horizontalBias: Float

    /// Bias toward positions closer to the anchor (only used when selecting between empty regions)
    let proximityBias: Float

    /// Padding around the hint to give it breathing room from nearby content
    let hintPadding: CGFloat

    /// Per-pixel complexity threshold for considering a region "empty" (0-100 scale)
    /// Regions with average complexity below this are considered blank/empty space
    var emptyComplexityThreshold: Float = 3.0  // Very low - effectively blank space only

    /// Whether to use mouse location as a positioning bias.
    ///     When `true`, SmartUIPositioner prefers positions closer to the mouse cursor.
    ///     When `false`, mouse location is ignored entirely — useful when positioning should be anchored to a specific region (e.g., pasted text) rather than the mouse.
    var useMouseBias: Bool = true

    /// Vertical distance bias when no empty regions are found (fallback mode)
    /// Higher values more strongly prefer positions far away vertically from anchor
    var fallbackVerticalDistanceBias: Float = 0.2  // Prefer far positions when no empty space

    static let `default` = UIPositioningConfig(
        uiSize: CGSize(width: 160, height: 28),
        searchPaddingX: 200,
        searchPaddingY: 30,
        useComplexityAnalysis: true,
        horizontalBias: 0.05,
        proximityBias: 0.1,
        hintPadding: 4
    )
}

/// Result of UI positioning calculation
struct UIPositioningResult {
    /// The calculated display area for the UI
    let displayArea: CGRect

    /// Whether the UI is positioned below the anchor (true) or above (false)
    let isDisplayedBelowAnchor: Bool

    /// The complexity score of the chosen position (lower = better, nil if not using complexity analysis)
    let complexityScore: Double?

    /// Whether an empty region was found (true) or fallback positioning was used (false)
    let foundEmptyRegion: Bool
}

/// Service for finding optimal UI positions on screen
@MainActor
final class SmartUIPositioner {

    // MARK: - Singleton

    static let shared = SmartUIPositioner()

    private init() {}

    // MARK: - Public API

    /// Finds the optimal position for a UI element near the given anchor point
    /// - Parameters:
    ///   - anchorPoint: The reference point (e.g., cursor position, mouse location)
    ///   - anchorBounds: Optional bounds of the anchor element (e.g., text selection rectangle)
    ///   - config: Configuration for positioning behavior
    /// - Returns: The optimal position result, or nil if positioning failed
    func findOptimalPosition(
        anchorPoint: CGPoint,
        anchorBounds: CGRect? = nil,
        config: UIPositioningConfig = .default,
        shouldUseSimplePositionFallback: Bool = true,
        changeRegion: CGRect? = nil,
        screenshot: CGImage? = nil,
        screenshotRegion: CGRect? = nil
    ) async -> UIPositioningResult? {
        // Get the screen containing the anchor point
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(anchorPoint) }) else {
            return nil
        }

        let visibleFrame = screen.visibleFrame

        // Use anchor bounds if available, otherwise create a small rect around anchor point
        let anchor = anchorBounds ?? CGRect(x: anchorPoint.x - 10, y: anchorPoint.y - 10, width: 20, height: 20)

        // Create search region: anchor bounds + padding in each direction
        var searchRegion = CGRect(
            x: anchor.minX - config.searchPaddingX,
            y: anchor.minY - config.searchPaddingY,
            width: anchor.width + config.searchPaddingX * 2,
            height: anchor.height + config.searchPaddingY * 2
        )

        // Clamp to visible screen frame
        searchRegion = searchRegion.intersection(visibleFrame)

        // Ensure search region is large enough
        guard searchRegion.width >= config.uiSize.width,
              searchRegion.height >= config.uiSize.height else {
            guard shouldUseSimplePositionFallback else { return nil }
            return simplePositionNearAnchor(
                anchorPoint: anchorPoint,
                anchorBounds: anchorBounds,
                uiSize: config.uiSize,
                visibleFrame: visibleFrame
            )
        }
        
//        VisualDiffDebugOverlay.shared.show(at: searchRegion, rects: [CGRect(x: 0, y: 0, width: searchRegion.width, height: searchRegion.height), CGRect(x: config.searchPaddingX, y: config.searchPaddingY, width: anchor.width, height: anchor.height)])

        // If not using complexity analysis, just use simple positioning
        if !config.useComplexityAnalysis {
            guard shouldUseSimplePositionFallback else { return nil }
            return simplePositionNearAnchor(
                anchorPoint: anchorPoint,
                anchorBounds: anchorBounds,
                uiSize: config.uiSize,
                visibleFrame: visibleFrame
            )
        }

        // Use GPU-based complexity analysis
        let anchorCenter = anchor.center
        guard let result = await findOptimalPositionUsingGPU(
            searchRegion: searchRegion,
            anchorRect: anchor,
            anchorCenter: anchorCenter,
            targetSize: config.uiSize,
            horizontalBias: config.horizontalBias,
            proximityBias: config.proximityBias,
            useMouseBias: config.useMouseBias,
            config: config,
            changeRegion: changeRegion,
            providedScreenshot: screenshot,
            providedScreenshotRegion: screenshotRegion
        ) else {
            guard shouldUseSimplePositionFallback else { return nil }
            return simplePositionNearAnchor(
                anchorPoint: anchorPoint,
                anchorBounds: anchorBounds,
                uiSize: config.uiSize,
                visibleFrame: visibleFrame
            )
        }

        // Determine if result is below anchor (in macOS coords, below = lower Y value)
        let isBelow = result.position.midY < anchorCenter.y

        return UIPositioningResult(
            displayArea: result.position,
            isDisplayedBelowAnchor: isBelow,
            complexityScore: result.complexity,
            foundEmptyRegion: result.foundEmptyRegion
        )
    }

    // MARK: - Private Methods

    /// Simple positioning without complexity analysis - positions near anchor
    private func simplePositionNearAnchor(
        anchorPoint: CGPoint,
        anchorBounds: CGRect?,
        uiSize: CGSize,
        visibleFrame: CGRect
    ) -> UIPositioningResult {
        let anchorMinY = anchorBounds?.minY ?? anchorPoint.y
        let anchorMaxY = anchorBounds?.maxY ?? anchorPoint.y
        let anchorX = anchorBounds?.minX ?? anchorPoint.x

        // Check space below vs above anchor
        let spaceBelow = anchorMinY - visibleFrame.minY
        let spaceAbove = visibleFrame.maxY - anchorMaxY

        let isBelow = spaceBelow >= uiSize.height || spaceBelow >= spaceAbove

        let y: CGFloat
        if isBelow {
            // Position below anchor (lower Y in macOS coords)
            y = anchorMinY - uiSize.height
        } else {
            // Position above anchor (higher Y in macOS coords)
            y = anchorMaxY
        }

        // Clamp X to screen bounds
        var x = anchorX
        x = max(visibleFrame.minX, min(x, visibleFrame.maxX - uiSize.width))

        // Clamp Y to screen bounds
        let clampedY = max(visibleFrame.minY, min(y, visibleFrame.maxY - uiSize.height))

        let displayArea = CGRect(x: x, y: clampedY, width: uiSize.width, height: uiSize.height)

        return UIPositioningResult(
            displayArea: displayArea,
            isDisplayedBelowAnchor: isBelow,
            complexityScore: nil,
            foundEmptyRegion: false
        )
    }

    /// GPU-accelerated optimal position finding within a constrained search region
    /// Uses a two-pass approach:
    /// 1. First, find if any "empty" regions exist (very low complexity)
    /// 2. If empty regions exist, use one of them (with optional selection biases)
    /// 3. If no empty regions, fall back to lowest complexity but prefer positions far away vertically
    private func findOptimalPositionUsingGPU(
        searchRegion: CGRect,
        anchorRect: CGRect,
        anchorCenter: CGPoint,
        targetSize: CGSize,
        horizontalBias: Float,
        proximityBias: Float,
        useMouseBias: Bool,
        config: UIPositioningConfig,
        changeRegion: CGRect? = nil,
        providedScreenshot: CGImage? = nil,
        providedScreenshotRegion: CGRect? = nil
    ) async -> (position: CGRect, complexity: Double, foundEmptyRegion: Bool)? {
        let tGPU = Date()
        log.info("[SmartPos] findOptimalPositionUsingGPU: start, searchRegion \(Int(searchRegion.width))x\(Int(searchRegion.height))")

        // Use the provided screenshot (cropped to searchRegion) if available.
        // This avoids a second screen capture seconds after paste detection, which can show stale content.
        let tScreenshot = Date()
        let screenshot: CGImage
        if let src = providedScreenshot, let srcRegion = providedScreenshotRegion {
            let scaleFactor = CGFloat(src.width) / srcRegion.width
            let cropRect = CGRect(
                x: (searchRegion.minX - srcRegion.minX) * scaleFactor,
                y: (srcRegion.maxY - searchRegion.maxY) * scaleFactor,
                width: searchRegion.width * scaleFactor,
                height: searchRegion.height * scaleFactor
            )
            if let cropped = src.cropping(to: cropRect) {
                screenshot = cropped
                log.info("[SmartPos] screenshot: cropped from provided image in \(Int(Date().timeIntervalSince(tScreenshot) * 1000))ms, \(cropped.width)x\(cropped.height)")
            } else {
                guard let captured = await ScreenRecordingManager.captureScreenRegionExcludingOwnWindows(at: searchRegion) else {
                    log.info("[SmartPos] screenshot: capture FAILED")
                    print("[SmartUIPositioner] Failed to capture screenshot")
                    return nil
                }
                screenshot = captured
                log.info("[SmartPos] screenshot: captured (crop failed) in \(Int(Date().timeIntervalSince(tScreenshot) * 1000))ms, \(captured.width)x\(captured.height)")
            }
        } else {
            guard let captured = await ScreenRecordingManager.captureScreenRegionExcludingOwnWindows(at: searchRegion) else {
                log.info("[SmartPos] screenshot: capture FAILED")
                print("[SmartUIPositioner] Failed to capture screenshot")
                return nil
            }
            screenshot = captured
            log.info("[SmartPos] screenshot: captured in \(Int(Date().timeIntervalSince(tScreenshot) * 1000))ms, \(captured.width)x\(captured.height)")
        }

        // Create pixel buffer from screenshot
        let tPixelBuffer = Date()
        guard let pixelBuffer = PixelBufferRenderer.createPixelBuffer(
            from: screenshot,
            width: screenshot.width,
            height: screenshot.height
        ) else {
            log.info("[SmartPos] createPixelBuffer: FAILED")
            print("[SmartUIPositioner] Failed to create pixel buffer")
            return nil
        }
        log.info("[SmartPos] createPixelBuffer: \(Int(Date().timeIntervalSince(tPixelBuffer) * 1000))ms")

        do {
            let gpu = FrequencyPatternGPU.shared

            // Compute per-pixel complexity (get CPU-readable version for calculating raw complexity)
            let tComplexityCPU = Date()
            let complexities = try gpu.computeFrequencyPatternPerPixel(
                pixelBuffer: pixelBuffer,
                width: screenshot.width,
                height: screenshot.height,
                windowSize: 20,
                samplingStride: 2,
                lineStride: 4,
                changeThreshold: 40.0
            )
            log.info("[SmartPos] computeFrequencyPatternPerPixel (CPU): \(Int(Date().timeIntervalSince(tComplexityCPU) * 1000))ms")

            // Also get GPU buffer for the rectangle search
            let tComplexityGPU = Date()
            let complexityBuffer = try gpu.computeFrequencyPatternPerPixelGPU(
                pixelBuffer: pixelBuffer,
                width: screenshot.width,
                height: screenshot.height,
                windowSize: 20,
                samplingStride: 2,
                lineStride: 4,
                changeThreshold: 40.0
            )
            log.info("[SmartPos] computeFrequencyPatternPerPixelGPU: \(Int(Date().timeIntervalSince(tComplexityGPU) * 1000))ms")

            // Convert anchor rect from macOS screen coordinates to image (Quartz) coordinates.
            // Image origin is top-left with Y increasing downward; macOS origin is bottom-left with Y increasing upward.
            let anchorRectInImage = (
                x: Float(anchorRect.minX - searchRegion.minX),
                y: Float(searchRegion.maxY - anchorRect.maxY),
                width: Float(anchorRect.width),
                height: Float(anchorRect.height)
            )

            // Convert optional change region (full pasted-text bounding box) to image coordinates.
            let changeRegionInImage: (x: Float, y: Float, width: Float, height: Float)? = changeRegion.map {
                (
                    x: Float($0.minX - searchRegion.minX),
                    y: Float(searchRegion.maxY - $0.maxY),
                    width: Float($0.width),
                    height: Float($0.height)
                )
            }

            // Search for exactly the hint size (no extra padding needed with new logic)
            let searchWidth = Int(targetSize.width)
            let searchHeight = Int(targetSize.height)

            // Calculate empty threshold for a rectangle (sum of per-pixel thresholds)
            let emptyRectangleThreshold = Double(config.emptyComplexityThreshold) * Double(searchWidth * searchHeight)

            print("[SmartUIPositioner] Starting positioning - searchRegion: \(Int(searchRegion.width))x\(Int(searchRegion.height)), emptyThreshold: \(emptyRectangleThreshold)")

            // PASS 1: Find the lowest complexity position with only anchor avoidance
            // No mouse proximity or other biases - we want to find the truly best empty region
            let tBias1 = Date()
            let anchorOnlyBias = try createAnchorAvoidanceOnlyBiasBuffer(
                width: screenshot.width,
                height: screenshot.height,
                anchorAvoidanceRect: anchorRectInImage,
                anchorAvoidancePenalty: 50.0
            )
            log.info("[SmartPos] createAnchorAvoidanceOnlyBiasBuffer: \(Int(Date().timeIntervalSince(tBias1) * 1000))ms")

            let tRect1 = Date()
            let initialResult = try gpu.findMinimumComplexityRectangle(
                complexityBuffer: complexityBuffer,
                width: screenshot.width,
                height: screenshot.height,
                targetWidth: searchWidth,
                targetHeight: searchHeight,
                biasBuffer: anchorOnlyBias
            )
            log.info("[SmartPos] findMinimumComplexityRectangle (Pass 1): \(Int(Date().timeIntervalSince(tRect1) * 1000))ms")

            // Calculate raw complexity (without bias) for the found position
            let rawComplexity = calculateRawRectangleComplexity(
                complexities: complexities,
                x: initialResult.position.x,
                y: initialResult.position.y,
                width: searchWidth,
                height: searchHeight,
                imageWidth: screenshot.width
            )

            let foundEmptyRegion = rawComplexity <= emptyRectangleThreshold
            log.info("[SmartPos] Pass 1: rawComplexity=\(Int(rawComplexity)), threshold=\(Int(emptyRectangleThreshold)), foundEmpty=\(foundEmptyRegion)")
            print("[SmartUIPositioner] Pass 1 result: rawComplexity=\(Int(rawComplexity)), threshold=\(Int(emptyRectangleThreshold)), foundEmpty=\(foundEmptyRegion)")

            let finalResult: (position: (x: Int, y: Int), complexity: Double)

            if foundEmptyRegion {
                // Found an empty region! Now run Pass 1b to select among empty regions using biases
                // Create bias buffer that:
                // 1. Adds massive penalty for non-empty pixels (filtering out non-empty regions)
                log.info("[SmartPos] Pass 1b: selecting among empty regions")
                print("[SmartUIPositioner] Pass 1b: Empty region found, selecting among empty regions")

                var mouseRelativeX: Float?
                var mouseRelativeY: Float?

                if useMouseBias {
                    let mouseLocation = NSEvent.mouseLocation
                    let mouseBuffer: CGFloat = 50
                    let expandedSearchRegion = searchRegion.insetBy(dx: -mouseBuffer, dy: -mouseBuffer)

                    if expandedSearchRegion.contains(mouseLocation) {
                        mouseRelativeX = Float(mouseLocation.x - searchRegion.minX)
                        mouseRelativeY = Float(searchRegion.maxY - mouseLocation.y)
                    }
                }

                let tBias1b = Date()
                let selectionBias = try createEmptyRegionSelectionBiasBuffer(
                    width: screenshot.width,
                    height: screenshot.height,
                    complexities: complexities,
                    emptyThreshold: config.emptyComplexityThreshold,
                    anchorAvoidanceRect: anchorRectInImage,
                    anchorAvoidancePenalty: 50.0,
                    mouseX: mouseRelativeX,
                    mouseY: mouseRelativeY,
                    mouseBias: proximityBias
                )
                log.info("[SmartPos] createEmptyRegionSelectionBiasBuffer (1b): \(Int(Date().timeIntervalSince(tBias1b) * 1000))ms")

                let tRect1b = Date()
                finalResult = try gpu.findMinimumComplexityRectangle(
                    complexityBuffer: complexityBuffer,
                    width: screenshot.width,
                    height: screenshot.height,
                    targetWidth: searchWidth,
                    targetHeight: searchHeight,
                    biasBuffer: selectionBias
                )
                log.info("[SmartPos] findMinimumComplexityRectangle (Pass 1b): \(Int(Date().timeIntervalSince(tRect1b) * 1000))ms")
            } else {
                // PASS 2: No empty region found - use fallback with inverted vertical bias
                // Prefer positions at vertical extremes and horizontally aligned with proximity reference
                log.info("[SmartPos] Pass 2: no empty region, using fallback")
                print("[SmartUIPositioner] Pass 2: No empty region, using fallback (vertical extremes)")

                var fallbackMouseX: Float?

                if useMouseBias {
                    let mouseLocation = NSEvent.mouseLocation
                    fallbackMouseX = Float(mouseLocation.x - searchRegion.minX)
                }

                let tBias2 = Date()
                let fallbackBias = try createFallbackBiasBuffer(
                    width: screenshot.width,
                    height: screenshot.height,
                    anchorAvoidanceRect: anchorRectInImage,
                    anchorAvoidancePenalty: 50.0,
                    verticalDistanceBias: config.fallbackVerticalDistanceBias,
                    targetWidth: searchWidth,
                    targetHeight: searchHeight,
                    mouseX: fallbackMouseX
                )
                log.info("[SmartPos] createFallbackBiasBuffer (Pass 2): \(Int(Date().timeIntervalSince(tBias2) * 1000))ms")

                let tRect2 = Date()
                finalResult = try gpu.findMinimumComplexityRectangle(
                    complexityBuffer: complexityBuffer,
                    width: screenshot.width,
                    height: screenshot.height,
                    targetWidth: searchWidth,
                    targetHeight: searchHeight,
                    biasBuffer: fallbackBias
                )
                log.info("[SmartPos] findMinimumComplexityRectangle (Pass 2): \(Int(Date().timeIntervalSince(tRect2) * 1000))ms")
            }

            // Clamp result position to valid bounds
            let maxValidX = screenshot.width - searchWidth
            let maxValidY = screenshot.height - searchHeight
            let clampedX = max(0, min(finalResult.position.x, maxValidX))
            let clampedY = max(0, min(finalResult.position.y, maxValidY))

            // Convert back to screen coordinates
            // The screenshot uses Quartz coordinates (origin top-left, Y increases downward)
            // macOS screen coordinates have origin bottom-left, Y increases upward
            // So we need to flip the Y coordinate within the search region
            let imageY = CGFloat(clampedY)
            let flippedY = searchRegion.height - imageY - CGFloat(searchHeight)

            let screenPosition = CGRect(
                x: searchRegion.minX + CGFloat(clampedX),
                y: searchRegion.minY + flippedY,
                width: targetSize.width,
                height: targetSize.height
            )

            log.info("[SmartPos] findOptimalPositionUsingGPU: total \(Int(Date().timeIntervalSince(tGPU) * 1000))ms, foundEmpty=\(foundEmptyRegion), complexity=\(Int(finalResult.complexity))")
            print("[SmartUIPositioner] Final position: (\(Int(screenPosition.origin.x)), \(Int(screenPosition.origin.y))), complexity=\(Int(finalResult.complexity)), foundEmpty=\(foundEmptyRegion)")

            #if DEBUG || ONIT_BETA
            saveDebugOutput(
                screenshot: screenshot,
                complexities: complexities,
                width: screenshot.width,
                height: screenshot.height,
                searchRegion: searchRegion,
                resultPositionInImage: finalResult.position,
                screenPosition: screenPosition,
                targetSize: targetSize,
                searchSize: CGSize(width: searchWidth, height: searchHeight),
                anchorRectInImage: anchorRectInImage,
                changeRegionInImage: changeRegionInImage,
                mouseLocationInImage: nil,
                mouseLocationScreen: NSEvent.mouseLocation,
                config: config,
                resultComplexity: finalResult.complexity
            )
            #endif

            return (screenPosition, finalResult.complexity, foundEmptyRegion)
        } catch {
            return nil
        }
    }

    /// Calculates the raw sum of complexity values for a rectangle at the given position
    private func calculateRawRectangleComplexity(
        complexities: [Double],
        x: Int,
        y: Int,
        width: Int,
        height: Int,
        imageWidth: Int
    ) -> Double {
        var sum: Double = 0
        for row in y..<(y + height) {
            for col in x..<(x + width) {
                let idx = row * imageWidth + col
                if idx < complexities.count {
                    sum += complexities[idx]
                }
            }
        }
        return sum
    }

    /// Creates a bias buffer with only anchor avoidance (no other biases)
    private func createAnchorAvoidanceOnlyBiasBuffer(
        width: Int,
        height: Int,
        anchorAvoidanceRect: (x: Float, y: Float, width: Float, height: Float),
        anchorAvoidancePenalty: Float
    ) throws -> MTLBuffer {
        let gpu = FrequencyPatternGPU.shared
        guard let device = gpu.device else {
            throw NSError(domain: "SmartUIPositioner", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Metal device"])
        }

        let pixelCount = width * height
        var biasValues = [Float](repeating: 0, count: pixelCount)

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                let fx = Float(x)
                let fy = Float(y)

                // Only apply anchor avoidance penalty
                if fx >= anchorAvoidanceRect.x && fx < anchorAvoidanceRect.x + anchorAvoidanceRect.width &&
                   fy >= anchorAvoidanceRect.y && fy < anchorAvoidanceRect.y + anchorAvoidanceRect.height {
                    biasValues[idx] = anchorAvoidancePenalty
                }
            }
        }

        guard let buffer = device.makeBuffer(
            bytes: biasValues,
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "SmartUIPositioner", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create anchor-only bias buffer"])
        }

        return buffer
    }

    /// Creates a bias buffer for selecting among empty regions
    /// Adds massive penalty for high-complexity pixels and applies selection biases for empty regions
    private func createEmptyRegionSelectionBiasBuffer(
        width: Int,
        height: Int,
        complexities: [Double],
        emptyThreshold: Float,
        anchorAvoidanceRect: (x: Float, y: Float, width: Float, height: Float),
        anchorAvoidancePenalty: Float,
        mouseX: Float?,
        mouseY: Float?,
        mouseBias: Float
    ) throws -> MTLBuffer {
        let gpu = FrequencyPatternGPU.shared
        guard let device = gpu.device else {
            throw NSError(domain: "SmartUIPositioner", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Metal device"])
        }

        let pixelCount = width * height
        var biasValues = [Float](repeating: 0, count: pixelCount)

        let nonEmptyPenaltyMultiplier: Float = 100.0

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                var totalBias: Float = 0
                let fx = Float(x)
                let fy = Float(y)

                // Get this pixel's complexity
                let pixelComplexity = Float(complexities[idx])

                // Add massive penalty for non-empty pixels
                // If complexity > threshold, add heavy penalty to make this region unattractive
                if pixelComplexity > emptyThreshold {
                    totalBias += pixelComplexity * nonEmptyPenaltyMultiplier
                }

                // Anchor avoidance penalty
                if fx >= anchorAvoidanceRect.x && fx < anchorAvoidanceRect.x + anchorAvoidanceRect.width &&
                   fy >= anchorAvoidanceRect.y && fy < anchorAvoidanceRect.y + anchorAvoidanceRect.height {
                    totalBias += anchorAvoidancePenalty
                }

                // Mouse proximity bias - favor positions closer to mouse
                // This helps select among multiple empty regions
                if let mx = mouseX, let my = mouseY {
                    let dx = fx - mx
                    let dy = fy - my
                    let distance = sqrt(dx * dx + dy * dy)
                    totalBias += distance * mouseBias
                }

                biasValues[idx] = totalBias
            }
        }

        guard let buffer = device.makeBuffer(
            bytes: biasValues,
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "SmartUIPositioner", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create empty region selection bias buffer"])
        }

        return buffer
    }

    /// Creates a bias buffer for fallback mode - strongly prefers vertical extremes and horizontal mouse alignment
    private func createFallbackBiasBuffer(
        width: Int,
        height: Int,
        anchorAvoidanceRect: (x: Float, y: Float, width: Float, height: Float),
        anchorAvoidancePenalty: Float,
        verticalDistanceBias: Float,
        targetWidth: Int,
        targetHeight: Int,
        mouseX: Float? = nil
    ) throws -> MTLBuffer {
        let gpu = FrequencyPatternGPU.shared
        guard let device = gpu.device else {
            throw NSError(domain: "SmartUIPositioner", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Metal device"])
        }

        let pixelCount = width * height
        var biasValues = [Float](repeating: 0, count: pixelCount)

        let targetH = Float(targetHeight)
        let imageHeight = Float(height)

        // Calculate anchor center Y for vertical distance calculation
        let anchorCenterY = anchorAvoidanceRect.y + anchorAvoidanceRect.height / 2

        // Very strong vertical distance bias - we want positions at the extremes
        let strongVerticalBias: Float = 2.0

        // Moderate horizontal mouse alignment bias
        let horizontalMouseBias: Float = 0.3

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                var totalBias: Float = 0
                let fx = Float(x)
                let fy = Float(y)

                // Anchor avoidance penalty (keep this - never cover selected text)
                if fx >= anchorAvoidanceRect.x && fx < anchorAvoidanceRect.x + anchorAvoidanceRect.width &&
                   fy >= anchorAvoidanceRect.y && fy < anchorAvoidanceRect.y + anchorAvoidanceRect.height {
                    totalBias += anchorAvoidancePenalty
                }

                // Strong preference for vertical extremes (top or bottom of search region)
                // Calculate how far this position is from the vertical center of the image
                let hintCenterY = fy + targetH / 2
                let imageCenterY = imageHeight / 2
                let distanceFromImageCenter = abs(hintCenterY - imageCenterY)
                let maxDistanceFromCenter = imageHeight / 2

                // Reward being at extremes: subtract more for positions farther from center
                // Normalize to 0-1 range and apply strong bias
                let normalizedExtremeDistance = distanceFromImageCenter / maxDistanceFromCenter
                totalBias -= normalizedExtremeDistance * strongVerticalBias * imageHeight

                // Also reward vertical distance from anchor specifically
                let verticalDistanceFromAnchor = abs(hintCenterY - anchorCenterY)
                totalBias -= verticalDistanceFromAnchor * verticalDistanceBias

                // Horizontal mouse alignment - prefer positions horizontally close to mouse
                if let mx = mouseX {
                    let horizontalDistance = abs(fx - mx)
                    totalBias += horizontalDistance * horizontalMouseBias
                }

                biasValues[idx] = totalBias
            }
        }

        guard let buffer = device.makeBuffer(
            bytes: biasValues,
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "SmartUIPositioner", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create fallback bias buffer"])
        }

        return buffer
    }

    // MARK: - Debug Output

    private func saveDebugOutput(
        screenshot: CGImage,
        complexities: [Double],
        width: Int,
        height: Int,
        searchRegion: CGRect,
        resultPositionInImage: (x: Int, y: Int),
        screenPosition: CGRect,
        targetSize: CGSize,
        searchSize: CGSize,
        anchorRectInImage: (x: Float, y: Float, width: Float, height: Float),
        changeRegionInImage: (x: Float, y: Float, width: Float, height: Float)?,
        mouseLocationInImage: (x: Float, y: Float)?,
        mouseLocationScreen: CGPoint,
        config: UIPositioningConfig,
        resultComplexity: Double
    ) {
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)

        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let debugFolderURL = documentsURL.appendingPathComponent("SmartPositioningDebug")
        try? FileManager.default.createDirectory(at: debugFolderURL, withIntermediateDirectories: true)

        // Save original screenshot
        let screenshotURL = debugFolderURL.appendingPathComponent("screenshot_\(timestamp).png")
        if let dest = CGImageDestinationCreateWithURL(screenshotURL as CFURL, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(dest, screenshot, nil)
            CGImageDestinationFinalize(dest)
        }

        // Save step4 coords for the debug viewer
        let spCoords = """
        step4_search_region:
          searchRegion (Quartz): (\(Int(searchRegion.minX)), \(Int(searchRegion.minY)), \(Int(searchRegion.width)), \(Int(searchRegion.height)))
          screenshot size (px): \(width)x\(height)
          screenPosition result (Quartz): (\(Int(screenPosition.minX)), \(Int(screenPosition.minY)), \(Int(screenPosition.width)), \(Int(screenPosition.height)))
        """
        try? spCoords.write(to: debugFolderURL.appendingPathComponent("sp_coords_\(timestamp).txt"), atomically: true, encoding: .utf8)

        // Create and save heatmap with overlays
        if let heatmap = createHeatmapImage(
            complexities: complexities,
            width: width,
            height: height,
            resultPositionInImage: resultPositionInImage,
            searchSize: searchSize,
            anchorRectInImage: anchorRectInImage,
            changeRegionInImage: changeRegionInImage,
            mouseLocationInImage: mouseLocationInImage
        ) {
            let heatmapURL = debugFolderURL.appendingPathComponent("heatmap_\(timestamp).png")
            if let dest = CGImageDestinationCreateWithURL(heatmapURL as CFURL, UTType.png.identifier as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, heatmap, nil)
                CGImageDestinationFinalize(dest)
            }
        }

        // Save comprehensive metadata for test reproduction
        var metadata: [String: Any] = [
            "timestamp": timestamp,
            "imageSize": ["width": width, "height": height],

            // Search region (screen coordinates)
            "searchRegion": [
                "x": searchRegion.origin.x,
                "y": searchRegion.origin.y,
                "width": searchRegion.width,
                "height": searchRegion.height
            ],

            // Result position in image coordinates
            "resultPositionInImage": ["x": resultPositionInImage.x, "y": resultPositionInImage.y],

            // Final screen position
            "screenPosition": [
                "x": screenPosition.origin.x,
                "y": screenPosition.origin.y,
                "width": screenPosition.width,
                "height": screenPosition.height
            ],

            // Target hint size (actual UI element size)
            "targetSize": ["width": targetSize.width, "height": targetSize.height],

            // Search size (target + padding)
            "searchSize": ["width": searchSize.width, "height": searchSize.height],

            // Anchor rect in image coordinates (the selected text area to avoid)
            "anchorRectInImage": [
                "x": anchorRectInImage.x,
                "y": anchorRectInImage.y,
                "width": anchorRectInImage.width,
                "height": anchorRectInImage.height
            ],

            // Mouse location (screen coordinates)
            "mouseLocationScreen": ["x": mouseLocationScreen.x, "y": mouseLocationScreen.y],

            // Result complexity score
            "resultComplexity": resultComplexity,

            // Configuration values used
            "config": [
                "uiSize": ["width": config.uiSize.width, "height": config.uiSize.height],
                "searchPaddingX": config.searchPaddingX,
                "searchPaddingY": config.searchPaddingY,
                "useComplexityAnalysis": config.useComplexityAnalysis,
                "horizontalBias": config.horizontalBias,
                "proximityBias": config.proximityBias,
                "hintPadding": config.hintPadding
            ],

            // Bias parameters used in calculation
            "biasParameters": [
                "anchorAvoidancePenalty": 50.0,
                "anchorProximityBias": 0.15
            ]
        ]

        // Add mouse location in image coordinates if available
        if let mouse = mouseLocationInImage {
            metadata["mouseLocationInImage"] = ["x": mouse.x, "y": mouse.y]
        }

        let metadataURL = debugFolderURL.appendingPathComponent("metadata_\(timestamp).json")
        if let jsonData = try? JSONSerialization.data(withJSONObject: metadata, options: [.prettyPrinted, .sortedKeys]) {
            try? jsonData.write(to: metadataURL)
        }
    }

    private func createHeatmapImage(
        complexities: [Double],
        width: Int,
        height: Int,
        resultPositionInImage: (x: Int, y: Int),
        searchSize: CGSize,
        anchorRectInImage: (x: Float, y: Float, width: Float, height: Float),
        changeRegionInImage: (x: Float, y: Float, width: Float, height: Float)?,
        mouseLocationInImage: (x: Float, y: Float)?
    ) -> CGImage? {
        // Find min/max for normalization
        let minComplexity = complexities.min() ?? 0
        let maxComplexity = complexities.max() ?? 100
        let range = maxComplexity - minComplexity

        // Create RGBA buffer
        var pixelData = [UInt8](repeating: 0, count: width * height * 4)

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                let complexity = complexities[idx]

                // Normalize to 0-1
                let normalized = range > 0 ? (complexity - minComplexity) / range : 0

                // Heatmap: low complexity = green, high complexity = red
                let red = UInt8(min(255, normalized * 255 * 2))
                let green = UInt8(min(255, (1 - normalized) * 255 * 2))
                let blue: UInt8 = 0
                let alpha: UInt8 = 180

                let pixelIdx = idx * 4
                pixelData[pixelIdx] = red
                pixelData[pixelIdx + 1] = green
                pixelData[pixelIdx + 2] = blue
                pixelData[pixelIdx + 3] = alpha
            }
        }

        // Helper to draw a rectangle outline
        func drawRectOutline(x: Int, y: Int, w: Int, h: Int, r: UInt8, g: UInt8, b: UInt8) {
            let hStart = max(0, x)
            let hEnd = min(width, x + w)
            let vStart = max(0, y)
            let vEnd = min(height, y + h)
            let bottomY = y + h - 1
            let rightX = x + w - 1

            // Top and bottom edges
            if hStart < hEnd {
                for px in hStart..<hEnd {
                    if y >= 0 && y < height {
                        let idx = (y * width + px) * 4
                        pixelData[idx] = r; pixelData[idx + 1] = g; pixelData[idx + 2] = b; pixelData[idx + 3] = 255
                    }
                    if bottomY >= 0 && bottomY < height {
                        let idx = (bottomY * width + px) * 4
                        pixelData[idx] = r; pixelData[idx + 1] = g; pixelData[idx + 2] = b; pixelData[idx + 3] = 255
                    }
                }
            }
            // Left and right edges
            if vStart < vEnd {
                for py in vStart..<vEnd {
                    if x >= 0 && x < width {
                        let idx = (py * width + x) * 4
                        pixelData[idx] = r; pixelData[idx + 1] = g; pixelData[idx + 2] = b; pixelData[idx + 3] = 255
                    }
                    if rightX >= 0 && rightX < width {
                        let idx = (py * width + rightX) * 4
                        pixelData[idx] = r; pixelData[idx + 1] = g; pixelData[idx + 2] = b; pixelData[idx + 3] = 255
                    }
                }
            }
        }

        // Helper to draw a crosshair at a point
        func drawCrosshair(x: Int, y: Int, size: Int, r: UInt8, g: UInt8, b: UInt8) {
            let hStart = max(0, x - size)
            let hEnd = min(width, x + size + 1)
            let vStart = max(0, y - size)
            let vEnd = min(height, y + size + 1)

            // Horizontal line
            if hStart < hEnd && y >= 0 && y < height {
                for px in hStart..<hEnd {
                    let idx = (y * width + px) * 4
                    pixelData[idx] = r; pixelData[idx + 1] = g; pixelData[idx + 2] = b; pixelData[idx + 3] = 255
                }
            }
            // Vertical line
            if vStart < vEnd && x >= 0 && x < width {
                for py in vStart..<vEnd {
                    let idx = (py * width + x) * 4
                    pixelData[idx] = r; pixelData[idx + 1] = g; pixelData[idx + 2] = b; pixelData[idx + 3] = 255
                }
            }
        }

        // Draw anchor rect outline in yellow (the area to avoid / selected text)
        drawRectOutline(
            x: Int(anchorRectInImage.x),
            y: Int(anchorRectInImage.y),
            w: Int(anchorRectInImage.width),
            h: Int(anchorRectInImage.height),
            r: 255, g: 255, b: 0
        )

        // Draw pasted text change region in magenta (the OCR-detected bounding box)
        if let cr = changeRegionInImage {
            drawRectOutline(x: Int(cr.x), y: Int(cr.y), w: Int(cr.width), h: Int(cr.height), r: 255, g: 0, b: 255)
        }

        // Draw result rectangle outline in blue (the chosen position)
        drawRectOutline(
            x: resultPositionInImage.x,
            y: resultPositionInImage.y,
            w: Int(searchSize.width),
            h: Int(searchSize.height),
            r: 0, g: 0, b: 255
        )

        // Draw mouse location as a cyan crosshair
        if let mouse = mouseLocationInImage {
            drawCrosshair(x: Int(mouse.x), y: Int(mouse.y), size: 10, r: 0, g: 255, b: 255)
        }

        // Create CGImage
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        return context.makeImage()
    }

    /// Creates a bias buffer that prefers positions closer to the anchor point
    private func createProximityBiasBuffer(
        width: Int,
        height: Int,
        anchorX: Float,
        anchorY: Float,
        proximityBias: Float,
        horizontalBias: Float
    ) throws -> MTLBuffer {
        let gpu = FrequencyPatternGPU.shared
        guard let device = gpu.device else {
            throw NSError(domain: "SmartUIPositioner", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Metal device"])
        }

        let pixelCount = width * height
        var biasValues = [Float](repeating: 0, count: pixelCount)

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x

                // Distance from anchor (normalized)
                let dx = Float(x) - anchorX
                let dy = Float(y) - anchorY
                let distance = sqrt(dx * dx + dy * dy)

                // Proximity bias: further from anchor = higher penalty
                let proxBias = distance * proximityBias

                // Horizontal bias: prefer left side slightly
                let hBias = Float(x) * horizontalBias

                biasValues[idx] = proxBias + hBias
            }
        }

        // Create GPU buffer
        guard let buffer = device.makeBuffer(
            bytes: biasValues,
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "SmartUIPositioner", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create bias buffer"])
        }

        return buffer
    }

    /// Creates a zero-filled bias buffer (no bias applied)
    private func createZeroBiasBuffer(
        width: Int,
        height: Int
    ) throws -> MTLBuffer {
        let gpu = FrequencyPatternGPU.shared
        guard let device = gpu.device else {
            throw NSError(domain: "SmartUIPositioner", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Metal device"])
        }

        let pixelCount = width * height
        let biasValues = [Float](repeating: 0, count: pixelCount)

        guard let buffer = device.makeBuffer(
            bytes: biasValues,
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "SmartUIPositioner", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create zero bias buffer"])
        }

        return buffer
    }

    /// Creates a combined bias buffer with mouse proximity, anchor avoidance, and anchor proximity
    /// - Parameters:
    ///   - targetWidth/targetHeight: Size of the hint rectangle being positioned (for edge-to-edge distance calculation)
    private func createCombinedBiasBuffer(
        width: Int,
        height: Int,
        mouseX: Float?,
        mouseY: Float?,
        mouseBias: Float,
        anchorAvoidanceRect: (x: Float, y: Float, width: Float, height: Float)? = nil,
        anchorAvoidancePenalty: Float = 0,
        anchorProximityBias: Float = 0,
        targetWidth: Int = 0,
        targetHeight: Int = 0
    ) throws -> MTLBuffer {
        let gpu = FrequencyPatternGPU.shared
        guard let device = gpu.device else {
            throw NSError(domain: "SmartUIPositioner", code: -1, userInfo: [NSLocalizedDescriptionKey: "No Metal device"])
        }

        let pixelCount = width * height
        var biasValues = [Float](repeating: 0, count: pixelCount)

        let targetW = Float(targetWidth)
        let targetH = Float(targetHeight)

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                var totalBias: Float = 0

                // Mouse proximity bias - favor positions closer to mouse
                if let mx = mouseX, let my = mouseY {
                    let dx = Float(x) - mx
                    let dy = Float(y) - my
                    let distance = sqrt(dx * dx + dy * dy)
                    totalBias += distance * mouseBias
                }

                // Anchor avoidance penalty (avoid covering selected text)
                // AND anchor proximity bias (favor positions close to anchor)
                if let rect = anchorAvoidanceRect {
                    let fx = Float(x)
                    let fy = Float(y)

                    // Check if this position is inside the anchor rect - apply avoidance penalty
                    if fx >= rect.x && fx < rect.x + rect.width &&
                       fy >= rect.y && fy < rect.y + rect.height {
                        totalBias += anchorAvoidancePenalty
                    }

                    // Anchor proximity bias - penalize positions far from anchor (edge-to-edge distance)
                    // This calculates the minimum distance from the hint rectangle to the anchor rectangle
                    if anchorProximityBias > 0 && targetW > 0 && targetH > 0 {
                        // Hint rectangle bounds (position x,y is top-left corner)
                        let hintMinX = fx
                        let hintMaxX = fx + targetW
                        let hintMinY = fy
                        let hintMaxY = fy + targetH

                        // Anchor rectangle bounds
                        let anchorMinX = rect.x
                        let anchorMaxX = rect.x + rect.width
                        let anchorMinY = rect.y
                        let anchorMaxY = rect.y + rect.height

                        // Calculate edge-to-edge distance (0 if overlapping)
                        // For X: gap is positive if hint is to the right of anchor or anchor is to the right of hint
                        let gapX = max(0, max(hintMinX - anchorMaxX, anchorMinX - hintMaxX))
                        // For Y: same logic
                        let gapY = max(0, max(hintMinY - anchorMaxY, anchorMinY - hintMaxY))

                        // Euclidean distance between closest edges
                        let edgeDistance = sqrt(gapX * gapX + gapY * gapY)
                        totalBias += edgeDistance * anchorProximityBias
                    }
                }

                biasValues[idx] = totalBias
            }
        }

        guard let buffer = device.makeBuffer(
            bytes: biasValues,
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "SmartUIPositioner", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create combined bias buffer"])
        }

        return buffer
    }
}

// MARK: - CGRect Extension

private extension CGRect {
    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
