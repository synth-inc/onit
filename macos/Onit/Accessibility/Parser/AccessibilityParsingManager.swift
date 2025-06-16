//
//  AccessibilityParsingManager.swift
//  Onit
//
//  Created by Assistant on 2025.
//

import Foundation
import ApplicationServices

/// Manages accessibility parsing requests and prevents duplicate parsing operations
@MainActor
final class AccessibilityParsingManager {
    
    // MARK: - Singleton
    
    static let shared = AccessibilityParsingManager()
    
    // MARK: - Types
    
    /// Completion handler for parsing results without bounding boxes
    typealias SimpleCompletionHandler = @MainActor ([String: String]) -> Void
    
    /// Completion handler for parsing results with bounding boxes
    typealias EnhancedCompletionHandler = @MainActor ([String: String], [TextBoundingBox]?) -> Void
    
    /// Cached parsing result
    private struct CachedResult {
        let results: [String: String]
        let boundingBoxes: [TextBoundingBox]?
        let timestamp: Date
        let hasBoundingBoxes: Bool
        let pid: pid_t?
        
        init(results: [String: String], boundingBoxes: [TextBoundingBox]?, hasBoundingBoxes: Bool, pid: pid_t?) {
            self.results = results
            self.boundingBoxes = boundingBoxes
            self.timestamp = Date()
            self.hasBoundingBoxes = hasBoundingBoxes
            self.pid = pid
        }
        
        /// Check if the cached result is still valid (within 30 seconds)
        var isValid: Bool {
            Date().timeIntervalSince(timestamp) < 30.0
        }
    }
    
    /// Internal request tracker
    private class ParseRequest {
        weak var target: AnyObject?
        let simpleCompletion: SimpleCompletionHandler?
        let enhancedCompletion: EnhancedCompletionHandler?
        let needsBoundingBoxes: Bool
        
        init(target: AnyObject,
             simpleCompletion: SimpleCompletionHandler?,
             enhancedCompletion: EnhancedCompletionHandler?,
             needsBoundingBoxes: Bool) {
            self.target = target
            self.simpleCompletion = simpleCompletion
            self.enhancedCompletion = enhancedCompletion
            self.needsBoundingBoxes = needsBoundingBoxes
        }
        
        var isValid: Bool {
            return target != nil
        }
        
        @MainActor
        func callCompletion(results: [String: String], boundingBoxes: [TextBoundingBox]?) {
            if let simpleCompletion = simpleCompletion {
                simpleCompletion(results)
            } else if let enhancedCompletion = enhancedCompletion {
                enhancedCompletion(results, boundingBoxes)
            }
        }
    }
    
    /// Ongoing parsing operation
    private class ParseOperation {
        let task: Task<([String: String], [TextBoundingBox]?), Never>
        var requests: [ParseRequest] = []
        let needsBoundingBoxes: Bool
        let pid: pid_t?
        
        init(task: Task<([String: String], [TextBoundingBox]?), Never>, needsBoundingBoxes: Bool, pid: pid_t?) {
            self.task = task
            self.needsBoundingBoxes = needsBoundingBoxes
            self.pid = pid
        }
        
        func addRequest(_ request: ParseRequest) {
            requests.append(request)
        }
        
        func cleanupInvalidRequests() {
            requests.removeAll { !$0.isValid }
        }
    }
    
    // MARK: - Properties
    
    /// Map of window element hash to ongoing parse operations
    private var ongoingOperations: [UInt: ParseOperation] = [:]
    
    /// Map of window element hash to cached results
    private var cachedResults: [UInt: CachedResult] = [:]
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Request parsing for a window element with simple text results only
    /// - Parameters:
    ///   - windowElement: The AXUIElement to parse
    ///   - requester: The object making the request (used for weak reference)
    ///   - completion: Callback with parsing results
    func requestParsing(
        for windowElement: AXUIElement,
        requester: AnyObject,
        completion: @escaping SimpleCompletionHandler
    ) {
        let elementHash = generateElementHash(windowElement)
        
        // Check if we have valid cached results
        if let cachedResult = validateAndCleanExpiredResult(for: elementHash) {
            print("AccessibilityParsingManager: Using cached results for element hash \(elementHash)")
            completion(cachedResult.results)
            return
        }
        
        let request = ParseRequest(
            target: requester,
            simpleCompletion: completion,
            enhancedCompletion: nil,
            needsBoundingBoxes: false
        )
        
        handleParseRequest(elementHash: elementHash, windowElement: windowElement, request: request)
    }
    
    /// Request parsing for a window element with enhanced results including bounding boxes
    /// - Parameters:
    ///   - windowElement: The AXUIElement to parse
    ///   - requester: The object making the request (used for weak reference)
    ///   - completion: Callback with parsing results and bounding boxes
    func requestEnhancedParsing(
        for windowElement: AXUIElement,
        requester: AnyObject,
        completion: @escaping EnhancedCompletionHandler
    ) {
        let elementHash = generateElementHash(windowElement)
        
        // Check if we have valid cached results with bounding boxes
        if let cachedResult = validateAndCleanExpiredResult(for: elementHash),
           cachedResult.hasBoundingBoxes {
            print("AccessibilityParsingManager: Using cached enhanced results for element hash \(elementHash)")
            completion(cachedResult.results, cachedResult.boundingBoxes)
            return
        }
        
        let request = ParseRequest(
            target: requester,
            simpleCompletion: nil,
            enhancedCompletion: completion,
            needsBoundingBoxes: true
        )
        
        handleParseRequest(elementHash: elementHash, windowElement: windowElement, request: request)
    }
    
    /// Cancel all parsing requests from a specific requester
    /// - Parameter requester: The object whose requests should be cancelled
    func cancelRequests(from requester: AnyObject) {
        for operation in ongoingOperations.values {
            operation.requests.removeAll { $0.target === requester }
        }
        
        // Clean up operations with no valid requests
        cleanupEmptyOperations()
    }
    
    /// Cancel all ongoing parsing operations
    func cancelAllOperations() {
        for operation in ongoingOperations.values {
            operation.task.cancel()
        }
        ongoingOperations.removeAll()
    }
    
    /// Clear all cached results
    func clearCache() {
        cachedResults.removeAll()
        print("AccessibilityParsingManager: Cleared all cached results")
    }
    
    /// Clear cached results for a specific window element
    func clearCache(for windowElement: AXUIElement) {
        let elementHash = generateElementHash(windowElement)
        cachedResults.removeValue(forKey: elementHash)
        print("AccessibilityParsingManager: Cleared cached results for element hash \(elementHash)")
    }
    
    /// Invalidate cached results for accessibility tree changes
    /// This should be called when the accessibility tree structure or content changes
    func invalidateCache(for windowElement: AXUIElement, reason: String) {
        let elementHash = generateElementHash(windowElement)
        if cachedResults.removeValue(forKey: elementHash) != nil {
            print("AccessibilityParsingManager: Invalidated cached results for element hash \(elementHash), reason: \(reason)")
        }
    }
    
    /// Invalidate cached results for a specific PID when the app's accessibility tree changes significantly
    func invalidateCache(for pid: pid_t, reason: String) {
        let keysToRemove = cachedResults.compactMap { (hash, cachedResult) -> UInt? in
            return cachedResult.pid == pid ? hash : nil
        }
        
        for key in keysToRemove {
            cachedResults.removeValue(forKey: key)
        }
        
        if !keysToRemove.isEmpty {
            print("AccessibilityParsingManager: Invalidated \(keysToRemove.count) cached results for PID \(pid), reason: \(reason)")
        }
    }
    
    // MARK: - Private Methods
    
    private func handleParseRequest(elementHash: UInt, windowElement: AXUIElement, request: ParseRequest) {
        if let existingOperation = ongoingOperations[elementHash] {
            // Operation already in progress
            existingOperation.cleanupInvalidRequests()
            
            // If existing operation doesn't include bounding boxes but new request needs them,
            // we need to start a new operation
            if !existingOperation.needsBoundingBoxes && request.needsBoundingBoxes {
                // Cancel existing operation and start new one with bounding boxes
                existingOperation.task.cancel()
                startNewParseOperation(elementHash: elementHash, windowElement: windowElement, initialRequest: request)
            } else {
                // Add request to existing operation
                existingOperation.addRequest(request)
            }
        } else {
            // No operation in progress, start new one
            startNewParseOperation(elementHash: elementHash, windowElement: windowElement, initialRequest: request)
        }
    }
    
    private func startNewParseOperation(elementHash: UInt, windowElement: AXUIElement, initialRequest: ParseRequest) {
        let needsBoundingBoxes = initialRequest.needsBoundingBoxes
        let pid = windowElement.pid()
        
        print("AccessibilityParsingManager: Starting new parse operation for element hash \(elementHash), needsBoundingBoxes: \(needsBoundingBoxes)")
        
        let task = Task { [weak self] () -> ([String: String], [TextBoundingBox]?) in
            let result = await AccessibilityParser.shared.getAllTextInElement(
                windowElement: windowElement,
                includeBoundingBoxes: needsBoundingBoxes
            )
            
            // Operation completed, notify all callbacks and cleanup
            await MainActor.run { [weak self] in
                self?.completeOperation(elementHash: elementHash, result: result, hasBoundingBoxes: needsBoundingBoxes, pid: pid)
            }
            
            return result
        }
        
        let operation = ParseOperation(task: task, needsBoundingBoxes: needsBoundingBoxes, pid: pid)
        operation.addRequest(initialRequest)
        ongoingOperations[elementHash] = operation
    }
    
    private func completeOperation(elementHash: UInt, result: ([String: String], [TextBoundingBox]?), hasBoundingBoxes: Bool, pid: pid_t?) {
        guard let operation = ongoingOperations.removeValue(forKey: elementHash) else { return }
        
        // Cache the result
        let cachedResult = CachedResult(
            results: result.0,
            boundingBoxes: result.1,
            hasBoundingBoxes: hasBoundingBoxes,
            pid: pid
        )
        cachedResults[elementHash] = cachedResult
        print("AccessibilityParsingManager: Cached results for element hash \(elementHash)")
        
        // Clean up invalid requests before calling completions
        operation.cleanupInvalidRequests()
        
        // Call all completion handlers
        for request in operation.requests {
            guard request.isValid else { continue }
            request.callCompletion(results: result.0, boundingBoxes: result.1)
        }
    }
    
    private func cleanupEmptyOperations() {
        let emptyOperations = ongoingOperations.compactMap { (key, operation) -> UInt? in
            operation.cleanupInvalidRequests()
            return operation.requests.isEmpty ? key : nil
        }
        
        for key in emptyOperations {
            if let operation = ongoingOperations.removeValue(forKey: key) {
                operation.task.cancel()
            }
        }
    }
    
    private func generateElementHash(_ element: AXUIElement) -> UInt {
        // Create a hash based on the element's properties that uniquely identify it
        var hasher = Hasher()
        
        // Use element's PID
        if let pid = element.pid() {
            hasher.combine(pid)
        }
        
        // Use element's role and title if available
        if let role = element.role() {
            hasher.combine(role)
        }
        
        if let title = element.title() {
            hasher.combine(title)
        }
        
        // Use element's frame if available for more specificity
        if let frame = element.frame() {
            hasher.combine(frame.origin.x)
            hasher.combine(frame.origin.y)
            hasher.combine(frame.size.width)
            hasher.combine(frame.size.height)
        }
        
        return UInt(hasher.finalize())
    }
    
    // MARK: - Direct Access Methods (for simple one-off usage)
    
    /// Direct parsing method that bypasses the request system for simple cases
    func parseElement(_ windowElement: AXUIElement) async -> [String: String] {
        let elementHash = generateElementHash(windowElement)
        
        // Check cache first
        if let cachedResult = validateAndCleanExpiredResult(for: elementHash) {
            print("AccessibilityParsingManager: Direct parse using cached results for element hash \(elementHash)")
            return cachedResult.results
        }
        
        // Parse and cache
        let results = await AccessibilityParser.shared.getAllTextInElement(windowElement: windowElement)
        let pid = windowElement.pid()
        let cachedResult = CachedResult(results: results, boundingBoxes: nil, hasBoundingBoxes: false, pid: pid)
        cachedResults[elementHash] = cachedResult
        print("AccessibilityParsingManager: Direct parse cached results for element hash \(elementHash)")
        
        return results
    }
    
    /// Direct parsing method that bypasses the request system for enhanced cases
    func parseElementWithBoundingBoxes(_ windowElement: AXUIElement) async -> ([String: String], [TextBoundingBox]?) {
        let elementHash = generateElementHash(windowElement)
        
        // Check cache first (must have bounding boxes)
        if let cachedResult = validateAndCleanExpiredResult(for: elementHash),
           cachedResult.hasBoundingBoxes {
            print("AccessibilityParsingManager: Direct enhanced parse using cached results for element hash \(elementHash)")
            return (cachedResult.results, cachedResult.boundingBoxes)
        }
        
        // Parse and cache
        let result = await AccessibilityParser.shared.getAllTextInElement(windowElement: windowElement, includeBoundingBoxes: true)
        let pid = windowElement.pid()
        let cachedResult = CachedResult(results: result.0, boundingBoxes: result.1, hasBoundingBoxes: true, pid: pid)
        cachedResults[elementHash] = cachedResult
        print("AccessibilityParsingManager: Direct enhanced parse cached results for element hash \(elementHash)")
        
        return result
    }
    
    /// Check if a cached result is still valid and remove it if not
    private func validateAndCleanExpiredResult(for elementHash: UInt) -> CachedResult? {
        guard let cachedResult = cachedResults[elementHash] else { return nil }
        
        if cachedResult.isValid {
            return cachedResult
        } else {
            cachedResults.removeValue(forKey: elementHash)
            print("AccessibilityParsingManager: Removed expired cached result for element hash \(elementHash)")
            return nil
        }
    }
}
