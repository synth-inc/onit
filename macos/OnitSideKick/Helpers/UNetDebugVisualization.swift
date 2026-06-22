//
//  UNetDebugVisualization.swift
//  Onit
//
//  Helper utilities to visualize UNet cursor detection results.
//

import AppKit
import CoreGraphics
import CoreML
import Foundation
import UniformTypeIdentifiers

struct UNetDebugVisualization {
    static func saveDebugVisualization(
        outputDir: URL,
        pixelBuffer: CVPixelBuffer,
        heatmap: MLMultiArray,
        detectedRect: CGRect,
        score: Double,
        inputSize: Int,
        tileNumber: Int
    ) {
        guard let tileImage = createCGImage(from: pixelBuffer),
              let heatmapImage = createHeatmapImage(from: heatmap, width: inputSize, height: inputSize) else {
            return
        }

        let compositeImage = createCompositeDebugImage(
            tileImage: tileImage,
            heatmapImage: heatmapImage,
            detectedRect: detectedRect,
            score: score,
            inputSize: inputSize
        )

        let baseFilename = String(format: "tile_%04d_score_%.3f", tileNumber, score)

        let tileURL = outputDir.appendingPathComponent("\(baseFilename)_tile.png")
        let heatmapURL = outputDir.appendingPathComponent("\(baseFilename)_heatmap.png")
        let compositeURL = outputDir.appendingPathComponent("\(baseFilename)_composite.png")

        saveImage(tileImage, to: tileURL)
        saveImage(heatmapImage, to: heatmapURL)
        saveImage(compositeImage, to: compositeURL)
    }

    // MARK: - Image creation helpers

    static func createCGImage(from pixelBuffer: CVPixelBuffer) -> CGImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)

        guard let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue)
            .union(.byteOrder32Little)

        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return nil
        }

        return context.makeImage()
    }

    static func createHeatmapImage(from heatmap: MLMultiArray, width: Int, height: Int) -> CGImage? {
        let count = heatmap.count

        // Float16 is only available on ARM64, use Float on x86_64
        var minValFloat: Float
        var maxValFloat: Float
        var rgbaData = [UInt8](repeating: 0, count: count * 4)

        #if arch(arm64)
        let ptr16 = heatmap.dataPointer.bindMemory(to: Float16.self, capacity: count)

        var minVal: Float16 = ptr16[0]
        var maxVal: Float16 = ptr16[0]
        for i in 0..<count {
            let val = ptr16[i]
            minVal = min(minVal, val)
            maxVal = max(maxVal, val)
        }

        minValFloat = Float(minVal)
        maxValFloat = Float(maxVal)
        let range = maxValFloat - minValFloat
        let rangeInv = range > 0.0001 ? 1.0 / range : 1.0

        for i in 0..<count {
            let normalized = (Float(ptr16[i]) - minValFloat) * rangeInv
            let (r, g, b) = heatmapColor(normalized)
            rgbaData[i * 4 + 0] = b  // BGRA
            rgbaData[i * 4 + 1] = g
            rgbaData[i * 4 + 2] = r
            rgbaData[i * 4 + 3] = 255
        }
        #else
        // x86_64 fallback: MLMultiArray uses Float on Intel
        let ptr32 = heatmap.dataPointer.bindMemory(to: Float.self, capacity: count)

        var minVal: Float = ptr32[0]
        var maxVal: Float = ptr32[0]
        for i in 0..<count {
            let val = ptr32[i]
            minVal = min(minVal, val)
            maxVal = max(maxVal, val)
        }

        minValFloat = minVal
        maxValFloat = maxVal
        let range = maxValFloat - minValFloat
        let rangeInv = range > 0.0001 ? 1.0 / range : 1.0

        for i in 0..<count {
            let normalized = (ptr32[i] - minValFloat) * rangeInv
            let (r, g, b) = heatmapColor(normalized)
            rgbaData[i * 4 + 0] = b  // BGRA
            rgbaData[i * 4 + 1] = g
            rgbaData[i * 4 + 2] = r
            rgbaData[i * 4 + 3] = 255
        }
        #endif

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let provider = CGDataProvider(data: Data(rgbaData) as CFData),
              let image = CGImage(
                width: width,
                height: height,
                bitsPerComponent: 8,
                bitsPerPixel: 32,
                bytesPerRow: width * 4,
                space: colorSpace,
                bitmapInfo: bitmapInfo,
                provider: provider,
                decode: nil,
                shouldInterpolate: false,
                intent: .defaultIntent
              ) else {
            return nil
        }

        return image
    }

    private static func heatmapColor(_ value: Float) -> (UInt8, UInt8, UInt8) {
        let v = max(0, min(1, value))
        if v < 0.33 {
            let t = v / 0.33
            return (UInt8(t * 255), 0, 0)
        } else if v < 0.66 {
            let t = (v - 0.33) / 0.33
            return (255, UInt8(t * 255), 0)
        } else {
            let t = (v - 0.66) / 0.34
            return (255, 255, UInt8(t * 255))
        }
    }

    static func createCompositeDebugImage(
        tileImage: CGImage,
        heatmapImage: CGImage,
        detectedRect: CGRect,
        score: Double,
        inputSize: Int
    ) -> CGImage {
        let width = inputSize * 2
        let height = inputSize

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)

        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        ) else {
            return tileImage
        }

        context.draw(tileImage, in: CGRect(x: 0, y: 0, width: inputSize, height: inputSize))
        context.draw(heatmapImage, in: CGRect(x: inputSize, y: 0, width: inputSize, height: inputSize))

        context.setFillColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.3)
        context.fill(detectedRect)

        context.setStrokeColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.8)
        context.setLineWidth(2.0)
        context.stroke(detectedRect)

        context.saveGState()
        let scoreText = String(format: "Score: %.3f", score) as NSString
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 14),
            .foregroundColor: NSColor.white
        ]
        let textSize = scoreText.size(withAttributes: attributes)
        let textY = CGFloat(height) - textSize.height - 7
        let textRect = CGRect(x: 5, y: textY - 2, width: textSize.width + 6, height: textSize.height + 4)
        context.setFillColor(red: 0, green: 0, blue: 0, alpha: 0.7)
        context.fill(textRect)
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        scoreText.draw(at: CGPoint(x: 8, y: 7), withAttributes: attributes)
        context.restoreGState()

        return context.makeImage() ?? tileImage
    }

    static func saveImage(_ image: CGImage, to url: URL) {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, kUTTypePNG as CFString, 1, nil) else {
            return
        }
        CGImageDestinationAddImage(destination, image, nil)
        CGImageDestinationFinalize(destination)
    }
}


