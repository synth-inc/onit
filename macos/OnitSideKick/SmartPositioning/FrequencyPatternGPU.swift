//
//  FrequencyPatternGPU.swift
//  Onit
//
//  GPU-accelerated frequency pattern detection for finding low-complexity screen areas
//

import Foundation
import Metal
import MetalKit
import CoreGraphics
import CoreVideo

/// Piecewise linear gradient definition: array of (position, bias) breakpoints
typealias BiasGradient = [(position: Float, bias: Float)]

final class FrequencyPatternGPU: @unchecked Sendable {
    static let shared = FrequencyPatternGPU()

    let device: MTLDevice?
    let queue: MTLCommandQueue?
    let lib: MTLLibrary?
    let frequencyPSO: MTLComputePipelineState?
    let frequencyPerPixelPSO: MTLComputePipelineState?
    let buildPrefixSumHorizontalPSO: MTLComputePipelineState?
    let buildPrefixSumVerticalPSO: MTLComputePipelineState?
    let findMinimumRectanglePSO: MTLComputePipelineState?
    let loader: MTKTextureLoader?
    let available: Bool
    let textureCache: CVMetalTextureCache?

    init() {
        guard let dev = MTLCreateSystemDefaultDevice(),
              let q = dev.makeCommandQueue(),
              let lib = try? dev.makeDefaultLibrary(bundle: .main),
              let frequencyFunction = lib.makeFunction(name: "frequency_pattern_per_tile"),
              let frequencyPSO = try? dev.makeComputePipelineState(function: frequencyFunction),
              let frequencyPerPixelFunction = lib.makeFunction(name: "frequency_pattern_per_pixel"),
              let frequencyPerPixelPSO = try? dev.makeComputePipelineState(function: frequencyPerPixelFunction),
              let buildPrefixSumHorizFunc = lib.makeFunction(name: "build_prefix_sum_horizontal"),
              let buildPrefixSumHorizPSO = try? dev.makeComputePipelineState(function: buildPrefixSumHorizFunc),
              let buildPrefixSumVertFunc = lib.makeFunction(name: "build_prefix_sum_vertical"),
              let buildPrefixSumVertPSO = try? dev.makeComputePipelineState(function: buildPrefixSumVertFunc),
              let findMinimumRectangleFunction = lib.makeFunction(name: "find_minimum_rectangle"),
              let findMinimumRectanglePSO = try? dev.makeComputePipelineState(function: findMinimumRectangleFunction) else {
            device = nil
            queue = nil
            lib = nil
            frequencyPSO = nil
            frequencyPerPixelPSO = nil
            buildPrefixSumHorizontalPSO = nil
            buildPrefixSumVerticalPSO = nil
            findMinimumRectanglePSO = nil
            loader = nil
            available = false
            textureCache = nil
            return
        }
        self.device = dev
        self.queue = q
        self.lib = lib
        self.loader = MTKTextureLoader(device: dev)
        self.frequencyPSO = frequencyPSO
        self.frequencyPerPixelPSO = frequencyPerPixelPSO
        self.buildPrefixSumHorizontalPSO = buildPrefixSumHorizPSO
        self.buildPrefixSumVerticalPSO = buildPrefixSumVertPSO
        self.findMinimumRectanglePSO = findMinimumRectanglePSO
        self.available = true
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, dev, nil, &cache)
        self.textureCache = cache
    }

    /// Creates a Metal texture from a CGImage
    func makeTexture(from image: CGImage) throws -> MTLTexture {
        guard let loader = loader else { throw NSError(domain: "Metal", code: -1) }
        let opts: [MTKTextureLoader.Option: Any] = [
            .SRGB: false,
            .textureUsage: NSNumber(value: MTLTextureUsage.shaderRead.rawValue),
            .textureStorageMode: NSNumber(value: MTLStorageMode.private.rawValue)
        ]
        return try loader.newTexture(cgImage: image, options: opts)
    }

    /// Creates a Metal texture from a CVPixelBuffer (more efficient)
    func makeTexture(from pixelBuffer: CVPixelBuffer) throws -> MTLTexture {
        guard let cache = textureCache else { throw NSError(domain: "Metal", code: -1) }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        var metalTexture: CVMetalTexture?
        let result = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            cache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &metalTexture
        )

        guard result == kCVReturnSuccess,
              let texture = metalTexture,
              let metalTexture = CVMetalTextureGetTexture(texture) else {
            throw NSError(domain: "Metal", code: -1)
        }

        return metalTexture
    }

    /// Compute frequency pattern complexity for all tiles in an image
    /// Returns an array of complexity percentages (0-100) for each tile
    func computeFrequencyPattern(
        pixelBuffer: CVPixelBuffer,
        width: Int,
        height: Int,
        tileSize: Int,
        samplingStride: Int = 2,
        lineStride: Int = 4,
        changeThreshold: Float = 40.0
    ) throws -> (tilesX: Int, tilesY: Int, complexities: [Double]) {
        guard available, let device, let queue, let frequencyPSO else {
            throw NSError(domain: "Metal", code: -2)
        }

        let tilesX = (width + tileSize - 1) / tileSize
        let tilesY = (height + tileSize - 1) / tileSize
        let tileCount = tilesX * tilesY

        let texture = try makeTexture(from: pixelBuffer)

        // Create buffers for results
        guard let changeCountBuf = device.makeBuffer(length: tileCount * MemoryLayout<UInt32>.size, options: .storageModeShared) else {
            throw NSError(domain: "Metal", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create change count buffer"])
        }
        guard let totalComparisonsBuf = device.makeBuffer(length: tileCount * MemoryLayout<UInt32>.size, options: .storageModeShared) else {
            throw NSError(domain: "Metal", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to create total comparisons buffer"])
        }

        // Zero out buffers
        memset(changeCountBuf.contents(), 0, tileCount * MemoryLayout<UInt32>.size)
        memset(totalComparisonsBuf.contents(), 0, tileCount * MemoryLayout<UInt32>.size)

        // Set up parameters
        var params = FrequencyParams(
            width: UInt32(width),
            height: UInt32(height),
            tileSize: UInt32(tileSize),
            samplingStride: UInt32(samplingStride),
            lineStride: UInt32(lineStride),
            changeThreshold: changeThreshold,
            tilesX: UInt32(tilesX),
            tilesY: UInt32(tilesY)
        )

        // Dispatch GPU computation
        guard let cb = queue.makeCommandBuffer() else {
            throw NSError(domain: "Metal", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to create command buffer"])
        }
        guard let enc = cb.makeComputeCommandEncoder() else {
            throw NSError(domain: "Metal", code: -6, userInfo: [NSLocalizedDescriptionKey: "Failed to create compute command encoder"])
        }

        enc.setComputePipelineState(frequencyPSO)
        enc.setTexture(texture, index: 0)
        enc.setBuffer(changeCountBuf, offset: 0, index: 0)
        enc.setBuffer(totalComparisonsBuf, offset: 0, index: 1)
        enc.setBytes(&params, length: MemoryLayout<FrequencyParams>.size, index: 2)

        // Dispatch threads (one per scan line, but only at lineStride intervals)
        let tpt = MTLSize(width: 1, height: 16, depth: 1)
        let tg = MTLSize(width: 1, height: (height + 15) / 16, depth: 1)
        enc.dispatchThreadgroups(tg, threadsPerThreadgroup: tpt)
        enc.endEncoding()

        cb.commit()
        cb.waitUntilCompleted()

        // Read back results and calculate percentages
        let changeCountPtr = changeCountBuf.contents().bindMemory(to: UInt32.self, capacity: tileCount)
        let totalComparisonsPtr = totalComparisonsBuf.contents().bindMemory(to: UInt32.self, capacity: tileCount)

        var complexities: [Double] = []
        for i in 0..<tileCount {
            let changes = Double(changeCountPtr[i])
            let total = Double(totalComparisonsPtr[i])

            if total > 0 {
                let percentage = (changes / total) * 100.0
                complexities.append(percentage)
            } else {
                complexities.append(0.0)
            }
        }

        return (tilesX, tilesY, complexities)
    }

    /// Compute frequency pattern complexity for each pixel in an image
    /// Returns an array of complexity percentages (0-100) for each pixel, row-major order
    func computeFrequencyPatternPerPixel(
        pixelBuffer: CVPixelBuffer,
        width: Int,
        height: Int,
        windowSize: Int,
        samplingStride: Int = 2,
        lineStride: Int = 4,
        changeThreshold: Float = 40.0
    ) throws -> [Double] {
        guard available, let device, let queue, let frequencyPerPixelPSO else {
            throw NSError(domain: "Metal", code: -2)
        }

        let pixelCount = width * height

        let texture = try makeTexture(from: pixelBuffer)

        // Create buffer for per-pixel complexity results
        guard let complexityBuf = device.makeBuffer(
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "Metal", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create complexity buffer"])
        }

        // Zero out buffer
        memset(complexityBuf.contents(), 0, pixelCount * MemoryLayout<Float>.size)

        // Set up parameters (tileSize is used as windowSize for per-pixel computation)
        var params = FrequencyParams(
            width: UInt32(width),
            height: UInt32(height),
            tileSize: UInt32(windowSize),
            samplingStride: UInt32(samplingStride),
            lineStride: UInt32(lineStride),
            changeThreshold: changeThreshold,
            tilesX: 0,
            tilesY: 0
        )

        // Dispatch GPU computation
        guard let cb = queue.makeCommandBuffer() else {
            throw NSError(domain: "Metal", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to create command buffer"])
        }
        guard let enc = cb.makeComputeCommandEncoder() else {
            throw NSError(domain: "Metal", code: -6, userInfo: [NSLocalizedDescriptionKey: "Failed to create compute command encoder"])
        }

        enc.setComputePipelineState(frequencyPerPixelPSO)
        enc.setTexture(texture, index: 0)
        enc.setBuffer(complexityBuf, offset: 0, index: 0)
        enc.setBytes(&params, length: MemoryLayout<FrequencyParams>.size, index: 2)

        // Dispatch one thread per pixel (16x16 threadgroups for efficiency)
        let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupsPerGrid = MTLSize(
            width: (width + 15) / 16,
            height: (height + 15) / 16,
            depth: 1
        )
        enc.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        enc.endEncoding()

        cb.commit()
        cb.waitUntilCompleted()

        // Read back results
        let complexityPtr = complexityBuf.contents().bindMemory(to: Float.self, capacity: pixelCount)
        return (0..<pixelCount).map { Double(complexityPtr[$0]) }
    }

    /// Compute frequency pattern complexity for each pixel and keep the buffer on GPU
    /// Returns the complexity buffer (stays on GPU) for further GPU processing
    func computeFrequencyPatternPerPixelGPU(
        pixelBuffer: CVPixelBuffer,
        width: Int,
        height: Int,
        windowSize: Int,
        samplingStride: Int = 2,
        lineStride: Int = 4,
        changeThreshold: Float = 40.0
    ) throws -> MTLBuffer {
        guard available, let device, let queue, let frequencyPerPixelPSO else {
            throw NSError(domain: "Metal", code: -2)
        }

        let pixelCount = width * height

        let texture = try makeTexture(from: pixelBuffer)

        // Create buffer for per-pixel complexity results (keep on GPU)
        guard let complexityBuf = device.makeBuffer(
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModePrivate
        ) else {
            throw NSError(domain: "Metal", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create complexity buffer"])
        }

        // Create a staging buffer to zero out, then copy to GPU buffer
        guard let stagingBuf = device.makeBuffer(
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "Metal", code: -4)
        }
        memset(stagingBuf.contents(), 0, pixelCount * MemoryLayout<Float>.size)

        // Set up parameters
        var params = FrequencyParams(
            width: UInt32(width),
            height: UInt32(height),
            tileSize: UInt32(windowSize),
            samplingStride: UInt32(samplingStride),
            lineStride: UInt32(lineStride),
            changeThreshold: changeThreshold,
            tilesX: 0,
            tilesY: 0
        )

        // Dispatch GPU computation
        guard let cb = queue.makeCommandBuffer() else {
            throw NSError(domain: "Metal", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to create command buffer"])
        }

        // Copy zeroed staging buffer to GPU buffer
        guard let blitEnc = cb.makeBlitCommandEncoder() else {
            throw NSError(domain: "Metal", code: -6)
        }
        blitEnc.copy(from: stagingBuf, sourceOffset: 0, to: complexityBuf, destinationOffset: 0, size: pixelCount * MemoryLayout<Float>.size)
        blitEnc.endEncoding()

        guard let enc = cb.makeComputeCommandEncoder() else {
            throw NSError(domain: "Metal", code: -7, userInfo: [NSLocalizedDescriptionKey: "Failed to create compute command encoder"])
        }

        enc.setComputePipelineState(frequencyPerPixelPSO)
        enc.setTexture(texture, index: 0)
        enc.setBuffer(complexityBuf, offset: 0, index: 0)
        enc.setBytes(&params, length: MemoryLayout<FrequencyParams>.size, index: 2)

        // Dispatch one thread per pixel
        let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupsPerGrid = MTLSize(
            width: (width + 15) / 16,
            height: (height + 15) / 16,
            depth: 1
        )
        enc.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        enc.endEncoding()

        cb.commit()
        cb.waitUntilCompleted()

        return complexityBuf
    }

    // MARK: - Bias Buffer Creation

    /// Interpolates a piecewise linear gradient at a given position
    private func interpolateGradient(_ gradient: BiasGradient, at position: Int, dimension: Int) -> Float {
        guard !gradient.isEmpty else { return 0.0 }

        let pos = Float(position)

        // If only one breakpoint, return its value
        if gradient.count == 1 {
            return gradient[0].bias
        }

        // Find surrounding breakpoints
        // Handle position before first breakpoint
        if pos <= gradient[0].position {
            return gradient[0].bias
        }

        // Handle position after last breakpoint
        if pos >= gradient[gradient.count - 1].position {
            return gradient[gradient.count - 1].bias
        }

        // Find the two breakpoints that surround this position
        for i in 0..<(gradient.count - 1) {
            let p1 = gradient[i]
            let p2 = gradient[i + 1]

            if pos >= p1.position && pos <= p2.position {
                // Linear interpolation
                let t = (pos - p1.position) / (p2.position - p1.position)
                return p1.bias + t * (p2.bias - p1.bias)
            }
        }

        // Fallback (shouldn't reach here)
        return 0.0
    }

    /// Creates a bias buffer with custom piecewise linear gradients in X and Y directions
    func createCustomBiasBuffer(
        width: Int,
        height: Int,
        horizontalGradient: BiasGradient?,
        verticalGradient: BiasGradient?
    ) throws -> MTLBuffer {
        guard let device = device else {
            throw NSError(domain: "Metal", code: -1, userInfo: [NSLocalizedDescriptionKey: "No device available"])
        }

        let pixelCount = width * height

        // Create bias values: combine horizontal and vertical gradients additively
        var biasValues = [Float](repeating: 0, count: pixelCount)
        for y in 0..<height {
            for x in 0..<width {
                let idx = y * width + x

                var bias: Float = 0.0

                // Add horizontal bias
                if let hGradient = horizontalGradient {
                    bias += interpolateGradient(hGradient, at: x, dimension: width)
                }

                // Add vertical bias
                if let vGradient = verticalGradient {
                    bias += interpolateGradient(vGradient, at: y, dimension: height)
                }

                biasValues[idx] = bias
            }
        }

        // Create staging buffer with bias values
        guard let stagingBuffer = device.makeBuffer(
            bytes: biasValues,
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "Metal", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to create staging buffer"])
        }

        // Create GPU buffer
        guard let gpuBuffer = device.makeBuffer(
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModePrivate
        ) else {
            throw NSError(domain: "Metal", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create GPU buffer"])
        }

        // Copy to GPU
        guard let queue = queue,
              let commandBuffer = queue.makeCommandBuffer(),
              let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
            throw NSError(domain: "Metal", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to create command buffer"])
        }

        blitEncoder.copy(from: stagingBuffer, sourceOffset: 0, to: gpuBuffer, destinationOffset: 0, size: pixelCount * MemoryLayout<Float>.size)
        blitEncoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        return gpuBuffer
    }

    /// Creates a bias buffer with a horizontal gradient that increases from left to right
    func createHorizontalBiasBuffer(
        width: Int,
        height: Int,
        biasPerPixel: Float = 0.1
    ) throws -> MTLBuffer {
        return try createCustomBiasBuffer(
            width: width,
            height: height,
            horizontalGradient: [(0, 0), (Float(width - 1), Float(width - 1) * biasPerPixel)],
            verticalGradient: nil
        )
    }

    /// Finds the rectangle of given size with minimum complexity sum using GPU
    func findMinimumComplexityRectangle(
        complexityBuffer: MTLBuffer,
        width: Int,
        height: Int,
        targetWidth: Int,
        targetHeight: Int,
        biasBuffer: MTLBuffer? = nil
    ) throws -> (position: (x: Int, y: Int), complexity: Double) {
        guard available, let device, let queue, let buildPrefixSumHorizontalPSO, let buildPrefixSumVerticalPSO, let findMinimumRectanglePSO else {
            throw NSError(domain: "Metal", code: -2)
        }

        let pixelCount = width * height

        // Create prefix sum buffer
        guard let prefixSumBuf = device.makeBuffer(
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModePrivate
        ) else {
            throw NSError(domain: "Metal", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to create prefix sum buffer"])
        }

        // Create buffers for minimum tracking
        guard let minSumBuf = device.makeBuffer(
            length: MemoryLayout<Float>.size,
            options: .storageModeShared
        ),
        let minPositionBuf = device.makeBuffer(
            length: MemoryLayout<UInt32>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "Metal", code: -4)
        }

        // Initialize minSum to infinity and minPosition to 0
        let minSumPtr = minSumBuf.contents().bindMemory(to: Float.self, capacity: 1)
        minSumPtr[0] = Float.infinity

        let minPositionPtr = minPositionBuf.contents().bindMemory(to: UInt32.self, capacity: 1)
        minPositionPtr[0] = 0  // Initialize to position (0, 0)

        // Zero out prefix sum buffer
        guard let stagingBuf = device.makeBuffer(
            length: pixelCount * MemoryLayout<Float>.size,
            options: .storageModeShared
        ) else {
            throw NSError(domain: "Metal", code: -5)
        }
        memset(stagingBuf.contents(), 0, pixelCount * MemoryLayout<Float>.size)

        guard let cb = queue.makeCommandBuffer() else {
            throw NSError(domain: "Metal", code: -6)
        }

        // Copy zeroed buffer to prefix sum buffer
        guard let blitEnc = cb.makeBlitCommandEncoder() else {
            throw NSError(domain: "Metal", code: -7)
        }
        blitEnc.copy(from: stagingBuf, sourceOffset: 0, to: prefixSumBuf, destinationOffset: 0, size: pixelCount * MemoryLayout<Float>.size)
        blitEnc.endEncoding()

        // Build prefix sum - horizontal pass (row-wise)
        guard let horizEnc = cb.makeComputeCommandEncoder() else {
            throw NSError(domain: "Metal", code: -8)
        }
        horizEnc.setComputePipelineState(buildPrefixSumHorizontalPSO)
        horizEnc.setBuffer(complexityBuffer, offset: 0, index: 0)
        horizEnc.setBuffer(prefixSumBuf, offset: 0, index: 1)
        var dimensions = SIMD2<UInt32>(UInt32(width), UInt32(height))
        horizEnc.setBytes(&dimensions, length: MemoryLayout<SIMD2<UInt32>>.size, index: 2)
        if let biasBuffer = biasBuffer {
            horizEnc.setBuffer(biasBuffer, offset: 0, index: 3)
        }

        // Dispatch one thread per row
        let horizThreadsPerGroup = MTLSize(width: 1, height: 16, depth: 1)
        let horizThreadgroupsPerGrid = MTLSize(
            width: 1,
            height: (height + 15) / 16,
            depth: 1
        )
        horizEnc.dispatchThreadgroups(horizThreadgroupsPerGrid, threadsPerThreadgroup: horizThreadsPerGroup)
        horizEnc.endEncoding()

        // Build prefix sum - vertical pass (column-wise)
        guard let vertEnc = cb.makeComputeCommandEncoder() else {
            throw NSError(domain: "Metal", code: -8)
        }
        vertEnc.setComputePipelineState(buildPrefixSumVerticalPSO)
        vertEnc.setBuffer(prefixSumBuf, offset: 0, index: 0)
        vertEnc.setBytes(&dimensions, length: MemoryLayout<SIMD2<UInt32>>.size, index: 1)

        // Dispatch one thread per column
        let vertThreadsPerGroup = MTLSize(width: 16, height: 1, depth: 1)
        let vertThreadgroupsPerGrid = MTLSize(
            width: (width + 15) / 16,
            height: 1,
            depth: 1
        )
        vertEnc.dispatchThreadgroups(vertThreadgroupsPerGrid, threadsPerThreadgroup: vertThreadsPerGroup)
        vertEnc.endEncoding()

        // Find minimum rectangle
        guard let minEnc = cb.makeComputeCommandEncoder() else {
            throw NSError(domain: "Metal", code: -9)
        }
        minEnc.setComputePipelineState(findMinimumRectanglePSO)
        minEnc.setBuffer(prefixSumBuf, offset: 0, index: 0)
        minEnc.setBuffer(minSumBuf, offset: 0, index: 1)
        minEnc.setBuffer(minPositionBuf, offset: 0, index: 2)

        var searchParams = RectangleSearchParams(
            width: UInt32(width),
            height: UInt32(height),
            targetWidth: UInt32(targetWidth),
            targetHeight: UInt32(targetHeight)
        )
        minEnc.setBytes(&searchParams, length: MemoryLayout<RectangleSearchParams>.size, index: 3)

        // Dispatch enough threads to cover all positions
        let minThreadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
        let minThreadgroupsPerGrid = MTLSize(
            width: (width + 15) / 16,
            height: (height + 15) / 16,
            depth: 1
        )
        minEnc.dispatchThreadgroups(minThreadgroupsPerGrid, threadsPerThreadgroup: minThreadsPerGroup)
        minEnc.endEncoding()

        cb.commit()
        cb.waitUntilCompleted()

        // Read back results
        let minSum = Double(minSumPtr[0])
//        let minPositionPtr = minPositionBuf.contents().bindMemory(to: UInt32.self, capacity: 1)
        let packedPos = minPositionPtr[0]
        let posX = Int(packedPos & 0xFFFF)
        let posY = Int((packedPos >> 16) & 0xFFFF)

        return ((posX, posY), minSum)
    }
}

private struct FrequencyParams {
    var width, height, tileSize, samplingStride, lineStride: UInt32
    var changeThreshold: Float
    var tilesX, tilesY: UInt32
}

private struct RectangleSearchParams {
    var width, height, targetWidth, targetHeight: UInt32
}
