//
//  String+LevenshteinDistance.swift
//  Onit
//
//  Created by Alex Carmack on 2024.
//

import Foundation
import Metal

extension String {
    /// Calculates the Levenshtein distance between this string and another string.
    /// The Levenshtein distance is the minimum number of single-character edits
    /// (insertions, deletions, or substitutions) required to change one string into another.
    ///
    /// - Parameter other: The string to compare against
    /// - Returns: The Levenshtein distance as an integer
    func levenshteinDistance(to other: String) -> Int {
        let selfArray = Array(self)
        let otherArray = Array(other)
        let selfCount = selfArray.count
        let otherCount = otherArray.count
        
        // Handle edge cases
        if selfCount == 0 { return otherCount }
        if otherCount == 0 { return selfCount }
        if self == other { return 0 }
        
        // Create a matrix to store distances
        var matrix = Array(repeating: Array(repeating: 0, count: otherCount + 1), count: selfCount + 1)
        
        // Initialize first row and column
        for i in 0...selfCount {
            matrix[i][0] = i
        }
        for j in 0...otherCount {
            matrix[0][j] = j
        }
        
        // Fill the matrix
        for i in 1...selfCount {
            for j in 1...otherCount {
                let cost = selfArray[i - 1] == otherArray[j - 1] ? 0 : 1
                
                let deletion = matrix[i - 1][j] + 1
                let insertion = matrix[i][j - 1] + 1
                let substitution = matrix[i - 1][j - 1] + cost
                
                matrix[i][j] = [deletion, insertion, substitution].min()!
            }
        }
        
        return matrix[selfCount][otherCount]
    }
    
    /// Calculates the Levenshtein distance between this string and another string with early exit.
    /// If the distance exceeds the maximum allowable distance at any point, returns nil.
    ///
    /// - Parameters:
    ///   - other: The string to compare against
    ///   - maxAllowableDistance: The maximum distance allowed before early exit
    /// - Returns: The Levenshtein distance as an Int if within bounds, nil otherwise
    func earlyExitLevenshteinDistance(to other: String, maxAllowableDistance: Int) -> Int? {
        let selfArray = Array(self)
        let otherArray = Array(other)
        let selfCount = selfArray.count
        let otherCount = otherArray.count
        
        // Handle edge cases
        if selfCount == 0 { return otherCount <= maxAllowableDistance ? otherCount : nil }
        if otherCount == 0 { return selfCount <= maxAllowableDistance ? selfCount : nil }
        if self == other { return 0 }
        
        // Early exit if the length difference alone exceeds the threshold
        if abs(selfCount - otherCount) > maxAllowableDistance { return nil }
        
        // Create a matrix to store distances
        var matrix = Array(repeating: Array(repeating: 0, count: otherCount + 1), count: selfCount + 1)
        
        // Initialize first row and column
        for i in 0...selfCount {
            matrix[i][0] = i
        }
        for j in 0...otherCount {
            matrix[0][j] = j
        }
        
        // Fill the matrix
        for i in 1...selfCount {
            var rowMin = Int.max
            
            for j in 1...otherCount {
                let cost = selfArray[i - 1] == otherArray[j - 1] ? 0 : 1
                
                let deletion = matrix[i - 1][j] + 1
                let insertion = matrix[i][j - 1] + 1
                let substitution = matrix[i - 1][j - 1] + cost
                
                matrix[i][j] = [deletion, insertion, substitution].min()!
                rowMin = min(rowMin, matrix[i][j])
            }
            
            // Early exit if minimum value in current row exceeds threshold
            if rowMin > maxAllowableDistance {
                return nil
            }
        }
        
        let finalDistance = matrix[selfCount][otherCount]
        return finalDistance <= maxAllowableDistance ? finalDistance : nil
    }
    
    /// GPU-accelerated word matching using Metal compute shaders.
    /// Finds matching words between two arrays with configurable distance threshold.
    ///
    /// - Parameters:
    ///   - ocrWords: Array of OCR-detected words
    ///   - accessibilityWords: Array of accessibility-detected words
    ///   - maxDistance: Maximum allowed Levenshtein distance for a match
    /// - Returns: Array of matched OCR words
    @MainActor
    static func findMatchingWords(ocrWords: [String], accessibilityWords: [String], maxDistance: Int = 2) -> [String] {
        return GPUWordMatcher.shared.findMatches(ocrWords: ocrWords, accessibilityWords: accessibilityWords, maxDistance: maxDistance)
    }
    
    /// Calculates the normalized Levenshtein distance as a percentage (0.0 to 1.0)
    /// where 0.0 means identical strings and 1.0 means completely different strings.
    ///
    /// - Parameter other: The string to compare against
    /// - Returns: Normalized distance as a Double between 0.0 and 1.0
    func normalizedLevenshteinDistance(to other: String) -> Double {
        let distance = levenshteinDistance(to: other)
        let maxLength = [self.count, other.count].max()!
        
        return maxLength == 0 ? 0.0 : Double(distance) / Double(maxLength)
    }
    
    /// Calculates the Levenshtein similarity as a percentage (0.0 to 1.0)
    /// where 1.0 means identical strings and 0.0 means completely different strings.
    ///
    /// - Parameter other: The string to compare against
    /// - Returns: Similarity as a Double between 0.0 and 1.0
    func levenshteinSimilarity(to other: String) -> Double {
        return 1.0 - normalizedLevenshteinDistance(to: other)
    }
    
    /// Checks if this string is similar to another string within a given threshold
    ///
    /// - Parameters:
    ///   - other: The string to compare against
    ///   - threshold: The similarity threshold (0.0 to 1.0). Default is 0.8
    /// - Returns: True if strings are similar within threshold, false otherwise
    func isSimilar(to other: String, threshold: Double = 0.8) -> Bool {
        return levenshteinSimilarity(to: other) >= threshold
    }
}

// MARK: - GPU Word Matcher

@MainActor
private final class GPUWordMatcher {
    static let shared = GPUWordMatcher()
    
    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private let pipelineState: MTLComputePipelineState?
    private let isGPUAvailable: Bool
    
    private init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported on this device")
            self.device = nil
            self.commandQueue = nil
            self.pipelineState = nil
            self.isGPUAvailable = false
            return
        }
        self.device = device
        
        guard let commandQueue = device.makeCommandQueue() else {
            print("Could not create command queue")
            self.commandQueue = nil
            self.pipelineState = nil
            self.isGPUAvailable = false
            return
        }
        self.commandQueue = commandQueue
        
        // Create compute pipeline
        guard let library = device.makeDefaultLibrary(),
              let function = library.makeFunction(name: "word_matcher_kernel") else {
            print("Could not load word_matcher_kernel function - falling back to CPU")
            self.pipelineState = nil
            self.isGPUAvailable = false
            return
        }
        
        do {
            self.pipelineState = try device.makeComputePipelineState(function: function)
            self.isGPUAvailable = true
        } catch {
            print("Could not create pipeline state: \(error) - falling back to CPU")
            self.pipelineState = nil
            self.isGPUAvailable = false
        }
    }
    
    func findMatches(ocrWords: [String], accessibilityWords: [String], maxDistance: Int) -> [String] {
        // Use CPU if GPU is not available or arrays are small
        if !isGPUAvailable || ocrWords.count < 50 || accessibilityWords.count < 50 {
            return findMatchesCPU(ocrWords: ocrWords, accessibilityWords: accessibilityWords, maxDistance: maxDistance)
        }
        
        do {
            return try findMatchesGPU(ocrWords: ocrWords, accessibilityWords: accessibilityWords, maxDistance: maxDistance)
        } catch {
            print("GPU word matching failed, falling back to CPU: \(error)")
            return findMatchesCPU(ocrWords: ocrWords, accessibilityWords: accessibilityWords, maxDistance: maxDistance)
        }
    }
    
    private func findMatchesGPU(ocrWords: [String], accessibilityWords: [String], maxDistance: Int) throws -> [String] {
        guard let device = device,
              let commandQueue = commandQueue,
              let pipelineState = pipelineState else {
            throw MetalError.deviceNotAvailable
        }
        
        let maxStringLength = 64 // Maximum string length we can handle
        
        // Convert strings to fixed-size character arrays
        let ocrData = ocrWords.prefix(1024).compactMap { word -> [UInt8]? in
            var data = Array(word.utf8)
            if data.count > maxStringLength {
                data = Array(data.prefix(maxStringLength))
            } else {
                data.append(contentsOf: Array(repeating: 0, count: maxStringLength - data.count))
            }
            return data
        }
        
        let accessibilityData = accessibilityWords.prefix(1024).compactMap { word -> [UInt8]? in
            var data = Array(word.utf8)
            if data.count > maxStringLength {
                data = Array(data.prefix(maxStringLength))
            } else {
                data.append(contentsOf: Array(repeating: 0, count: maxStringLength - data.count))
            }
            return data
        }
        guard !ocrData.isEmpty && !accessibilityData.isEmpty else {
            return []
        }
        
        // Create Metal buffers
        let ocrBuffer = device.makeBuffer(bytes: ocrData.flatMap { $0 }, length: ocrData.count * maxStringLength, options: [])
        let accessibilityBuffer = device.makeBuffer(bytes: accessibilityData.flatMap { $0 }, length: accessibilityData.count * maxStringLength, options: [])
        let resultBuffer = device.makeBuffer(length: ocrData.count * MemoryLayout<UInt32>.size, options: [])
        
        guard let ocrBuffer = ocrBuffer,
              let accessibilityBuffer = accessibilityBuffer,
              let resultBuffer = resultBuffer else {
            throw MetalError.bufferCreationFailed
        }
        
        // Create command buffer and encoder
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            throw MetalError.commandBufferCreationFailed
        }
        
        // Set up compute pipeline
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setBuffer(ocrBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(accessibilityBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(resultBuffer, offset: 0, index: 2)
        
        var params = WordMatcherParams(
            ocrCount: UInt32(ocrData.count),
            accessibilityCount: UInt32(accessibilityData.count),
            maxStringLength: UInt32(maxStringLength),
            maxDistance: UInt32(maxDistance)
        )
        computeEncoder.setBytes(&params, length: MemoryLayout<WordMatcherParams>.size, index: 3)
        
        // Dispatch threads
        let threadsPerThreadgroup = MTLSize(width: min(pipelineState.threadExecutionWidth, ocrData.count), height: 1, depth: 1)
        let threadgroupsPerGrid = MTLSize(width: (ocrData.count + threadsPerThreadgroup.width - 1) / threadsPerThreadgroup.width, height: 1, depth: 1)
        
        computeEncoder.dispatchThreadgroups(threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // Read results
        let resultPointer = resultBuffer.contents().bindMemory(to: UInt32.self, capacity: ocrData.count)
        let results = Array(UnsafeBufferPointer(start: resultPointer, count: ocrData.count))
        
        // Return matched words
        return results.enumerated().compactMap { index, hasMatch in
            hasMatch > 0 ? ocrWords[index] : nil
        }
    }
    
    private func findMatchesCPU(ocrWords: [String], accessibilityWords: [String], maxDistance: Int) -> [String] {
        let accessibilityWordsSet = Set(accessibilityWords)
        return ocrWords.filter { ocrWord in
            accessibilityWordsSet.contains { accessibilityWord in
                let lengthDiff = abs(ocrWord.count - accessibilityWord.count)
                guard lengthDiff <= maxDistance else { return false }
                return ocrWord.earlyExitLevenshteinDistance(to: accessibilityWord, maxAllowableDistance: maxDistance) != nil
            }
        }
    }
}

private struct WordMatcherParams {
    let ocrCount: UInt32
    let accessibilityCount: UInt32
    let maxStringLength: UInt32
    let maxDistance: UInt32
}

private enum MetalError: Error {
    case deviceNotAvailable
    case bufferCreationFailed
    case commandBufferCreationFailed
}
