//
//  SmartUIPositionerTests.swift
//  OnitTests
//
//  Created by Claude on 12/4/25.
//

import Foundation
import AppKit
import Testing
import CoreGraphics
import CoreVideo
import ImageIO
import UniformTypeIdentifiers
@testable import OnitSideKick

/// Tests for SmartUIPositioner that replay saved debug data to verify positioning calculations.
/// Debug data is saved to ~/Documents/SmartPositioningDebug/ when the app runs with debug output enabled.
struct SmartUIPositionerTests {

    // MARK: - Test Data Structures

    /// Metadata structure matching the JSON saved by SmartUIPositioner
    struct PositioningMetadata: Codable {
        let timestamp: Int
        let imageSize: Size
        let searchRegion: Rect
        let resultPositionInImage: Position
        let screenPosition: Rect
        let targetSize: Size
        let searchSize: Size
        let anchorRectInImage: Rect
        let mouseLocationScreen: Position
        let mouseLocationInImage: Position?
        let resultComplexity: Double
        let config: Config
        let biasParameters: BiasParameters

        struct Size: Codable {
            let width: Double
            let height: Double
        }

        struct Position: Codable {
            let x: Double
            let y: Double
        }

        struct Rect: Codable {
            let x: Double
            let y: Double
            let width: Double
            let height: Double
        }

        struct Config: Codable {
            let uiSize: Size
            let searchPaddingX: Double
            let searchPaddingY: Double
            let useComplexityAnalysis: Bool
            let horizontalBias: Double
            let proximityBias: Double
            let hintPadding: Double
        }

        struct BiasParameters: Codable {
            let anchorAvoidancePenalty: Double
            let anchorProximityBias: Double
        }
    }

    /// A single test case loaded from debug output
    struct TestCase {
        let metadata: PositioningMetadata
        let screenshotURL: URL
        let timestamp: Int
    }

    // MARK: - Test Case Loading

    /// Returns the debug folder URL
    private static func debugFolderURL() -> URL? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsURL.appendingPathComponent("SmartPositioningDebug")
    }

    /// Loads all test cases from the debug folder
    private static func loadTestCases() throws -> [TestCase] {
        guard let debugFolder = debugFolderURL() else {
            return []
        }

        guard FileManager.default.fileExists(atPath: debugFolder.path) else {
            return []
        }

        let contents = try FileManager.default.contentsOfDirectory(at: debugFolder, includingPropertiesForKeys: nil)

        // Find all metadata JSON files
        let metadataFiles = contents.filter { $0.lastPathComponent.hasPrefix("metadata_") && $0.pathExtension == "json" }

        var testCases: [TestCase] = []

        for metadataURL in metadataFiles {
            // Extract timestamp from filename (metadata_<timestamp>.json)
            let filename = metadataURL.deletingPathExtension().lastPathComponent
            guard let timestampString = filename.split(separator: "_").last,
                  let timestamp = Int(timestampString) else {
                continue
            }

            // Find corresponding screenshot
            let screenshotURL = debugFolder.appendingPathComponent("screenshot_\(timestamp).png")
            guard FileManager.default.fileExists(atPath: screenshotURL.path) else {
                continue
            }

            // Load metadata
            let jsonData = try Data(contentsOf: metadataURL)
            let metadata = try JSONDecoder().decode(PositioningMetadata.self, from: jsonData)

            testCases.append(TestCase(
                metadata: metadata,
                screenshotURL: screenshotURL,
                timestamp: timestamp
            ))
        }

        return testCases.sorted { $0.timestamp < $1.timestamp }
    }

    /// Loads a specific test case by timestamp
    private static func loadTestCase(timestamp: Int) throws -> TestCase? {
        guard let debugFolder = debugFolderURL() else {
            return nil
        }

        let metadataURL = debugFolder.appendingPathComponent("metadata_\(timestamp).json")
        let screenshotURL = debugFolder.appendingPathComponent("screenshot_\(timestamp).png")

        guard FileManager.default.fileExists(atPath: metadataURL.path),
              FileManager.default.fileExists(atPath: screenshotURL.path) else {
            return nil
        }

        let jsonData = try Data(contentsOf: metadataURL)
        let metadata = try JSONDecoder().decode(PositioningMetadata.self, from: jsonData)

        return TestCase(
            metadata: metadata,
            screenshotURL: screenshotURL,
            timestamp: timestamp
        )
    }

    // MARK: - Calculation Replay

    /// Re-runs the positioning calculation for a test case and returns the result
    @MainActor
    private static func replayCalculation(testCase: TestCase) throws -> (position: (x: Int, y: Int), complexity: Double)? {
        // Load screenshot
        guard let imageSource = CGImageSourceCreateWithURL(testCase.screenshotURL as CFURL, nil),
              let screenshot = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            throw NSError(domain: "SmartUIPositionerTests", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to load screenshot"])
        }

        let metadata = testCase.metadata
        let width = screenshot.width
        let height = screenshot.height

        // Verify image size matches metadata
        guard width == Int(metadata.imageSize.width), height == Int(metadata.imageSize.height) else {
            throw NSError(domain: "SmartUIPositionerTests", code: 2,
                         userInfo: [NSLocalizedDescriptionKey: "Screenshot size doesn't match metadata"])
        }

        // Create pixel buffer from screenshot
        guard let pixelBuffer = PixelBufferRenderer.createPixelBuffer(
            from: screenshot,
            width: width,
            height: height
        ) else {
            throw NSError(domain: "SmartUIPositionerTests", code: 3,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create pixel buffer"])
        }

        let gpu = FrequencyPatternGPU.shared

        // Compute complexity buffer
        let complexityBuffer = try gpu.computeFrequencyPatternPerPixelGPU(
            pixelBuffer: pixelBuffer,
            width: width,
            height: height,
            windowSize: 20,
            samplingStride: 2,
            lineStride: 4,
            changeThreshold: 40.0
        )

        // Create bias buffer with the same parameters
        let biasBuffer = try createBiasBuffer(
            width: width,
            height: height,
            metadata: metadata
        )

        // Find minimum complexity rectangle
        let result = try gpu.findMinimumComplexityRectangle(
            complexityBuffer: complexityBuffer,
            width: width,
            height: height,
            targetWidth: Int(metadata.searchSize.width),
            targetHeight: Int(metadata.searchSize.height),
            biasBuffer: biasBuffer
        )

        return (result.position, result.complexity)
    }

    /// Creates a bias buffer matching the original calculation
    @MainActor
    private static func createBiasBuffer(
        width: Int,
        height: Int,
        metadata: PositioningMetadata
    ) throws -> MTLBuffer {
        let gpu = FrequencyPatternGPU.shared
        guard let device = gpu.device else {
            throw NSError(domain: "SmartUIPositionerTests", code: 4,
                         userInfo: [NSLocalizedDescriptionKey: "No Metal device"])
        }

        let pixelCount = width * height
        var biasValues = [Float](repeating: 0, count: pixelCount)

        let mouseBias = Float(metadata.config.proximityBias)
        let anchorAvoidancePenalty = Float(metadata.biasParameters.anchorAvoidancePenalty)
        let anchorProximityBias = Float(metadata.biasParameters.anchorProximityBias)

        let anchorRect = metadata.anchorRectInImage

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                var totalBias: Float = 0

                // Mouse proximity bias
                if let mouse = metadata.mouseLocationInImage {
                    let dx = Float(x) - Float(mouse.x)
                    let dy = Float(y) - Float(mouse.y)
                    let distance = sqrt(dx * dx + dy * dy)
                    totalBias += distance * mouseBias
                }

                // Anchor avoidance and proximity
                let fx = Float(x)
                let fy = Float(y)

                // Check if inside anchor rect
                if fx >= Float(anchorRect.x) && fx < Float(anchorRect.x + anchorRect.width) &&
                   fy >= Float(anchorRect.y) && fy < Float(anchorRect.y + anchorRect.height) {
                    totalBias += anchorAvoidancePenalty
                }

                // Anchor proximity bias
                if anchorProximityBias > 0 {
                    let anchorCenterX = Float(anchorRect.x + anchorRect.width / 2)
                    let anchorCenterY = Float(anchorRect.y + anchorRect.height / 2)
                    let dx = fx - anchorCenterX
                    let dy = fy - anchorCenterY
                    let distance = sqrt(dx * dx + dy * dy)
                    totalBias += distance * anchorProximityBias
                }

                biasValues[idx] = totalBias
            }
        }

        guard let buffer = device.makeBuffer(
            bytes: biasValues,
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "SmartUIPositionerTests", code: 5,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create bias buffer"])
        }

        return buffer
    }

    // MARK: - Tests

    @Test("Replay all saved positioning calculations")
    @MainActor
    func replayAllCalculations() throws {
        let testCases = try Self.loadTestCases()

        guard !testCases.isEmpty else {
            print("No test cases found in SmartPositioningDebug folder. Run the app with debug output enabled to generate test data.")
            return
        }

        print("Found \(testCases.count) test case(s)")

        var passCount = 0
        var failCount = 0

        for testCase in testCases {
            let metadata = testCase.metadata

            guard let result = try Self.replayCalculation(testCase: testCase) else {
                print("❌ [\(testCase.timestamp)] Failed to replay calculation")
                failCount += 1
                continue
            }

            let expectedX = Int(metadata.resultPositionInImage.x)
            let expectedY = Int(metadata.resultPositionInImage.y)

            let positionMatches = result.position.x == expectedX && result.position.y == expectedY
            let complexityMatches = abs(result.complexity - metadata.resultComplexity) < 0.001

            if positionMatches && complexityMatches {
                print("✅ [\(testCase.timestamp)] Position (\(result.position.x), \(result.position.y)) complexity \(result.complexity)")
                passCount += 1
            } else {
                print("❌ [\(testCase.timestamp)] Mismatch!")
                print("   Expected: position (\(expectedX), \(expectedY)), complexity \(metadata.resultComplexity)")
                print("   Got:      position (\(result.position.x), \(result.position.y)), complexity \(result.complexity)")
                failCount += 1
            }
        }

        print("\nResults: \(passCount) passed, \(failCount) failed")
        #expect(failCount == 0, "Some calculations did not match expected results")
    }

    @Test("Verify positioning avoids anchor rect")
    @MainActor
    func verifyAnchorAvoidance() throws {
        let testCases = try Self.loadTestCases()

        guard !testCases.isEmpty else {
            print("No test cases found. Skipping anchor avoidance test.")
            return
        }

        for testCase in testCases {
            let metadata = testCase.metadata
            let resultX = metadata.resultPositionInImage.x
            let resultY = metadata.resultPositionInImage.y
            let searchWidth = metadata.searchSize.width
            let searchHeight = metadata.searchSize.height

            let anchorRect = metadata.anchorRectInImage

            // Check if result rectangle overlaps with anchor rect
            let resultRight = resultX + searchWidth
            let resultBottom = resultY + searchHeight
            let anchorRight = anchorRect.x + anchorRect.width
            let anchorBottom = anchorRect.y + anchorRect.height

            let overlapsX = resultX < anchorRight && resultRight > anchorRect.x
            let overlapsY = resultY < anchorBottom && resultBottom > anchorRect.y
            let overlaps = overlapsX && overlapsY

            if overlaps {
                print("⚠️ [\(testCase.timestamp)] Result overlaps with anchor rect")
                print("   Result: (\(resultX), \(resultY)) size (\(searchWidth), \(searchHeight))")
                print("   Anchor: (\(anchorRect.x), \(anchorRect.y)) size (\(anchorRect.width), \(anchorRect.height))")
            } else {
                print("✅ [\(testCase.timestamp)] Result does not overlap anchor rect")
            }
        }
    }

    @Test("List available test cases")
    func listTestCases() throws {
        let testCases = try Self.loadTestCases()

        if testCases.isEmpty {
            print("No test cases found in SmartPositioningDebug folder.")
            print("To generate test data:")
            print("1. Enable saveDebugOutput in SmartUIPositioner.swift")
            print("2. Run the app and select some text to trigger positioning")
            print("3. Check ~/Documents/SmartPositioningDebug/ for output")
            return
        }

        print("Available test cases (\(testCases.count) total):")
        for testCase in testCases {
            let date = Date(timeIntervalSince1970: Double(testCase.timestamp) / 1000)
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .medium
            print("  - \(testCase.timestamp) (\(formatter.string(from: date)))")
            print("    Image: \(Int(testCase.metadata.imageSize.width))x\(Int(testCase.metadata.imageSize.height))")
            print("    Result: (\(Int(testCase.metadata.resultPositionInImage.x)), \(Int(testCase.metadata.resultPositionInImage.y)))")
            print("    Complexity: \(testCase.metadata.resultComplexity)")
        }
    }

    @Test("Diagnose positioning for specific test case")
    @MainActor
    func diagnosePositioning() throws {
        // Load a specific test case by timestamp
        let targetTimestamp = 1764892181879 // Change this to the timestamp you want to analyze

        guard let testCase = try Self.loadTestCase(timestamp: targetTimestamp) else {
            print("Test case \(targetTimestamp) not found")
            return
        }

        let metadata = testCase.metadata
        print("=== Diagnosing test case \(targetTimestamp) ===")
        print("Image size: \(Int(metadata.imageSize.width))x\(Int(metadata.imageSize.height))")
        print("Search size (hint + padding): \(Int(metadata.searchSize.width))x\(Int(metadata.searchSize.height))")
        print("Anchor rect: x=\(Int(metadata.anchorRectInImage.x)), y=\(Int(metadata.anchorRectInImage.y)), w=\(Int(metadata.anchorRectInImage.width)), h=\(Int(metadata.anchorRectInImage.height))")
        print("Mouse in image: \(metadata.mouseLocationInImage?.x ?? -1), \(metadata.mouseLocationInImage?.y ?? -1)")
        print("Original result position: (\(Int(metadata.resultPositionInImage.x)), \(Int(metadata.resultPositionInImage.y)))")
        print("Original result complexity: \(metadata.resultComplexity)")
        print("")

        // Load screenshot and compute complexities
        guard let imageSource = CGImageSourceCreateWithURL(testCase.screenshotURL as CFURL, nil),
              let screenshot = CGImageSourceCreateImageAtIndex(imageSource, 0, nil) else {
            print("Failed to load screenshot")
            return
        }

        let width = screenshot.width
        let height = screenshot.height

        guard let pixelBuffer = PixelBufferRenderer.createPixelBuffer(
            from: screenshot,
            width: width,
            height: height
        ) else {
            print("Failed to create pixel buffer")
            return
        }

        let gpu = FrequencyPatternGPU.shared

        // Get raw complexity values
        let complexities = try gpu.computeFrequencyPatternPerPixel(
            pixelBuffer: pixelBuffer,
            width: width,
            height: height,
            windowSize: 20,
            samplingStride: 2,
            lineStride: 4,
            changeThreshold: 40.0
        )

        // Get GPU complexity buffer for rectangle search
        let complexityBuffer = try gpu.computeFrequencyPatternPerPixelGPU(
            pixelBuffer: pixelBuffer,
            width: width,
            height: height,
            windowSize: 20,
            samplingStride: 2,
            lineStride: 4,
            changeThreshold: 40.0
        )

        // Create bias buffer with the NEW reduced anchor proximity bias (0.02 instead of 0.5)
        let newAnchorProximityBias: Float = 0.02
        let biasBuffer = try Self.createBiasBufferWithCustomAnchorBias(
            width: width,
            height: height,
            metadata: metadata,
            anchorProximityBias: newAnchorProximityBias
        )

        // Find minimum complexity rectangle with new bias
        let searchWidth = Int(metadata.searchSize.width)
        let searchHeight = Int(metadata.searchSize.height)

        let newResult = try gpu.findMinimumComplexityRectangle(
            complexityBuffer: complexityBuffer,
            width: width,
            height: height,
            targetWidth: searchWidth,
            targetHeight: searchHeight,
            biasBuffer: biasBuffer
        )

        print("=== NEW RESULT with anchorProximityBias=\(newAnchorProximityBias) ===")
        print("New result position: (\(newResult.position.x), \(newResult.position.y))")
        print("New result complexity: \(newResult.complexity)")
        print("")

        // Save a new heatmap with the new result position
        saveComparisonHeatmap(
            complexities: complexities,
            width: width,
            height: height,
            originalPosition: (x: Int(metadata.resultPositionInImage.x), y: Int(metadata.resultPositionInImage.y)),
            newPosition: newResult.position,
            searchWidth: searchWidth,
            searchHeight: searchHeight,
            anchorRect: metadata.anchorRectInImage,
            mouseLocation: metadata.mouseLocationInImage,
            timestamp: targetTimestamp
        )

        // Compute bias values for comparison
        let maxX = width - searchWidth
        let maxY = height - searchHeight

        let anchorRect = metadata.anchorRectInImage
        let anchorCenterX = Float(anchorRect.x + anchorRect.width / 2)
        let anchorCenterY = Float(anchorRect.y + anchorRect.height / 2)

        print("Anchor center: (\(anchorCenterX), \(anchorCenterY))")
        print("Valid position range: x=[0, \(maxX)], y=[0, \(maxY)]")
        print("")

        // Define positions to compare
        let positions: [(name: String, x: Int, y: Int)] = [
            ("Original result", Int(metadata.resultPositionInImage.x), Int(metadata.resultPositionInImage.y)),
            ("NEW result", newResult.position.x, newResult.position.y),
            ("Lower-right corner", maxX, maxY),
            ("Lower-right (slightly in)", max(0, maxX - 20), max(0, maxY - 10)),
            ("Top-left corner", 0, 0),
            ("Center", maxX / 2, maxY / 2)
        ]

        print("=== Position Analysis (with NEW anchorProximityBias=\(newAnchorProximityBias)) ===")
        print(String(format: "%-25s %10s %10s %10s %10s", "Position", "RawCompl", "MouseBias", "AnchBias", "Total"))
        print(String(repeating: "-", count: 70))

        for pos in positions {
            guard pos.x >= 0 && pos.x <= maxX && pos.y >= 0 && pos.y <= maxY else {
                print("\(pos.name): OUT OF BOUNDS")
                continue
            }

            // Sum complexity in the rectangle
            var rawComplexity: Double = 0
            for dy in 0..<searchHeight {
                for dx in 0..<searchWidth {
                    let px = pos.x + dx
                    let py = pos.y + dy
                    if px < width && py < height {
                        rawComplexity += complexities[py * width + px]
                    }
                }
            }

            // Calculate mouse bias (distance from mouse to position center)
            var mouseBias: Float = 0
            if let mouse = metadata.mouseLocationInImage {
                let posCenterX = Float(pos.x) + Float(searchWidth) / 2
                let posCenterY = Float(pos.y) + Float(searchHeight) / 2
                let dx = posCenterX - Float(mouse.x)
                let dy = posCenterY - Float(mouse.y)
                let distance = sqrt(dx * dx + dy * dy)
                mouseBias = distance * Float(metadata.config.proximityBias)
            }

            // Calculate anchor proximity bias with NEW value
            let posCenterX = Float(pos.x) + Float(searchWidth) / 2
            let posCenterY = Float(pos.y) + Float(searchHeight) / 2
            let dx = posCenterX - anchorCenterX
            let dy = posCenterY - anchorCenterY
            let anchorDistance = sqrt(dx * dx + dy * dy)
            let anchorBias = anchorDistance * newAnchorProximityBias

            // Note: The actual algorithm sums per-pixel biases, but this gives a rough idea
            // For a more accurate comparison, we'd need to sum per-pixel
            let estimatedTotal = rawComplexity + Double(mouseBias) * Double(searchWidth * searchHeight) + Double(anchorBias) * Double(searchWidth * searchHeight)

            print(String(format: "%-25s %10.0f %10.1f %10.1f %10.0f",
                        pos.name, rawComplexity, mouseBias * Float(searchWidth * searchHeight),
                        anchorBias * Float(searchWidth * searchHeight), estimatedTotal))
        }
    }

    /// Creates a bias buffer with a custom anchor proximity bias value
    @MainActor
    private static func createBiasBufferWithCustomAnchorBias(
        width: Int,
        height: Int,
        metadata: PositioningMetadata,
        anchorProximityBias: Float
    ) throws -> MTLBuffer {
        let gpu = FrequencyPatternGPU.shared
        guard let device = gpu.device else {
            throw NSError(domain: "SmartUIPositionerTests", code: 4,
                         userInfo: [NSLocalizedDescriptionKey: "No Metal device"])
        }

        let pixelCount = width * height
        var biasValues = [Float](repeating: 0, count: pixelCount)

        let mouseBias = Float(metadata.config.proximityBias)
        let anchorAvoidancePenalty = Float(metadata.biasParameters.anchorAvoidancePenalty)

        let anchorRect = metadata.anchorRectInImage

        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x
                var totalBias: Float = 0

                // Mouse proximity bias
                if let mouse = metadata.mouseLocationInImage {
                    let dx = Float(x) - Float(mouse.x)
                    let dy = Float(y) - Float(mouse.y)
                    let distance = sqrt(dx * dx + dy * dy)
                    totalBias += distance * mouseBias
                }

                // Anchor avoidance and proximity
                let fx = Float(x)
                let fy = Float(y)

                // Check if inside anchor rect
                if fx >= Float(anchorRect.x) && fx < Float(anchorRect.x + anchorRect.width) &&
                   fy >= Float(anchorRect.y) && fy < Float(anchorRect.y + anchorRect.height) {
                    totalBias += anchorAvoidancePenalty
                }

                // Anchor proximity bias with CUSTOM value
                if anchorProximityBias > 0 {
                    let anchorCenterX = Float(anchorRect.x + anchorRect.width / 2)
                    let anchorCenterY = Float(anchorRect.y + anchorRect.height / 2)
                    let dx = fx - anchorCenterX
                    let dy = fy - anchorCenterY
                    let distance = sqrt(dx * dx + dy * dy)
                    totalBias += distance * anchorProximityBias
                }

                biasValues[idx] = totalBias
            }
        }

        guard let buffer = device.makeBuffer(
            bytes: biasValues,
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "SmartUIPositionerTests", code: 5,
                         userInfo: [NSLocalizedDescriptionKey: "Failed to create bias buffer"])
        }

        return buffer
    }

    /// Saves a comparison heatmap showing both original and new positions
    private func saveComparisonHeatmap(
        complexities: [Double],
        width: Int,
        height: Int,
        originalPosition: (x: Int, y: Int),
        newPosition: (x: Int, y: Int),
        searchWidth: Int,
        searchHeight: Int,
        anchorRect: PositioningMetadata.Rect,
        mouseLocation: PositioningMetadata.Position?,
        timestamp: Int
    ) {
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

            if hStart < hEnd && y >= 0 && y < height {
                for px in hStart..<hEnd {
                    let idx = (y * width + px) * 4
                    pixelData[idx] = r; pixelData[idx + 1] = g; pixelData[idx + 2] = b; pixelData[idx + 3] = 255
                }
            }
            if vStart < vEnd && x >= 0 && x < width {
                for py in vStart..<vEnd {
                    let idx = (py * width + x) * 4
                    pixelData[idx] = r; pixelData[idx + 1] = g; pixelData[idx + 2] = b; pixelData[idx + 3] = 255
                }
            }
        }

        // Draw anchor rect outline in yellow
        drawRectOutline(
            x: Int(anchorRect.x),
            y: Int(anchorRect.y),
            w: Int(anchorRect.width),
            h: Int(anchorRect.height),
            r: 255, g: 255, b: 0
        )

        // Draw ORIGINAL result rectangle outline in RED (old position)
        drawRectOutline(
            x: originalPosition.x,
            y: originalPosition.y,
            w: searchWidth,
            h: searchHeight,
            r: 255, g: 0, b: 0
        )

        // Draw NEW result rectangle outline in BLUE (new position)
        drawRectOutline(
            x: newPosition.x,
            y: newPosition.y,
            w: searchWidth,
            h: searchHeight,
            r: 0, g: 100, b: 255
        )

        // Draw mouse location as a cyan crosshair
        if let mouse = mouseLocation {
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
        ),
        let heatmap = context.makeImage() else {
            print("Failed to create heatmap image")
            return
        }

        // Save to debug folder
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return
        }

        let debugFolderURL = documentsURL.appendingPathComponent("SmartPositioningDebug")
        let heatmapURL = debugFolderURL.appendingPathComponent("heatmap_comparison_\(timestamp).png")

        if let dest = CGImageDestinationCreateWithURL(heatmapURL as CFURL, UTType.png.identifier as CFString, 1, nil) {
            CGImageDestinationAddImage(dest, heatmap, nil)
            CGImageDestinationFinalize(dest)
            print("Saved comparison heatmap to: \(heatmapURL.path)")
        }
    }
}
