//
//  PixelBufferRenderer.swift
//  Onit
//
//  Created by Kévin Naudin on 08/13/2025.
//

import AppKit
import CoreGraphics
import CoreVideo

final class PixelBufferRenderer {
    
    static func createPixelBuffer(from image: CGImage, width: Int, height: Int, letterboxResize: Bool = false, verticalFlip: Bool = false) -> CVPixelBuffer? {
        var pixelBuffer: CVPixelBuffer?
        let attrs: [CFString: Any] = [
            kCVPixelBufferMetalCompatibilityKey: true,
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
        ]
        let status = CVPixelBufferCreate(kCFAllocatorDefault, width, height, kCVPixelFormatType_32BGRA, attrs as CFDictionary, &pixelBuffer)
        guard status == kCVReturnSuccess, let buffer = pixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(buffer, [])
        defer { CVPixelBufferUnlockBaseAddress(buffer, []) }
        guard let base = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
        guard let ctx = CGContext(
            data: base,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else { return nil }
        
        ctx.interpolationQuality = .high
        
        if letterboxResize {
            ctx.setFillColor(NSColor.black.cgColor)
            ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
            
            let imgW = CGFloat(image.width)
            let imgH = CGFloat(image.height)
            let scaleFit = min(CGFloat(width) / imgW, CGFloat(height) / imgH)
            let drawW = imgW * scaleFit
            let drawH = imgH * scaleFit
            let offsetX = (CGFloat(width) - drawW) * 0.5
            let offsetY = (CGFloat(height) - drawH) * 0.5
            
            if verticalFlip {
                ctx.saveGState()
                ctx.translateBy(x: 0, y: CGFloat(height))
                ctx.scaleBy(x: 1, y: -1)
                ctx.draw(image, in: CGRect(x: offsetX, y: offsetY, width: drawW, height: drawH))
                ctx.restoreGState()
            } else {
                ctx.draw(image, in: CGRect(x: offsetX, y: offsetY, width: drawW, height: drawH))
            }
        } else {
            if verticalFlip {
                ctx.saveGState()
                ctx.translateBy(x: 0, y: CGFloat(height))
                ctx.scaleBy(x: 1, y: -1)
                ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
                ctx.restoreGState()
            } else {
                ctx.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        }

        return buffer
    }
}
