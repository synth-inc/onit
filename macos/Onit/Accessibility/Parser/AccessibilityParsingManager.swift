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
        let elementHash = CFHash(windowElement)
        
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
        let elementHash = CFHash(windowElement)
        
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
        let elementHash = CFHash(windowElement)
        cachedResults.removeValue(forKey: elementHash)
        print("AccessibilityParsingManager: Cleared cached results for element hash \(elementHash)")
    }
    
    /// Invalidate cached results for accessibility tree changes
    /// This should be called when the accessibility tree structure or content changes
    func invalidateCache(for windowElement: AXUIElement, reason: String) {
        let elementHash = CFHash(windowElement)
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

    
    // MARK: - Direct Access Methods (for simple one-off usage)
    
    /// Split accessibility text around a target element
    /// - Parameter targetElement: The element to split text around
    /// - Returns: A tuple containing (precedingText, followingText) split around the target element
    func splitTextAroundElement(_ targetElement: AXUIElement) async -> (precedingText: String, followingText: String) {
        // Get the window element for the target by traversing up the parent hierarchy
        guard let windowElement = findWindowElement(for: targetElement) else {
            print("AccessibilityParsingManager: Could not find window for target element")
            return ("", "")
        }
        
        let elementHash = CFHash(windowElement)
        
        // Get cached or fresh parsing results
        let fullText: String
        if let cachedResult = validateAndCleanExpiredResult(for: elementHash) {
            print("AccessibilityParsingManager: Using cached results for text splitting")
            fullText = cachedResult.results["screen"] ?? ""
        } else {
            print("AccessibilityParsingManager: Parsing fresh results for text splitting")
            let results = await AccessibilityParser.shared.getAllTextInElement(windowElement: windowElement)
            let pid = windowElement.pid()
            let cachedResult = CachedResult(results: results, boundingBoxes: nil, hasBoundingBoxes: false, pid: pid)
            cachedResults[elementHash] = cachedResult
            fullText = results["screen"] ?? ""
        }
        
        // Find the target element's value or closest element with value
        let (elementValue, isBeforeTarget) = await findElementValueForSplitting(targetElement: targetElement, windowElement: windowElement)
        
        guard !elementValue.isEmpty else {
            print("AccessibilityParsingManager: No element value found for splitting")
            return ("", fullText)
        }
        
        // Split the text around the element value
        return splitTextAroundValue(fullText: fullText, elementValue: elementValue, isElementBeforeTarget: isBeforeTarget)
    }
    
    /// Find the window element by traversing up the parent hierarchy
    private func findWindowElement(for element: AXUIElement) -> AXUIElement? {
        var currentElement = element
        
        // Traverse up the parent hierarchy looking for a window
        while true {
            let role = currentElement.role()
            
            // Check if this element is a window
            if role == kAXWindowRole || role == "AXWindow" {
                return currentElement
            }
            
            // Move to parent element
            guard let parent = currentElement.parent() else {
                break
            }
            
            currentElement = parent
        }
        
        // If we didn't find a window, try to use the element itself if it's an application
        let role = element.role()
        if role == kAXApplicationRole || role == "AXApplication" {
            // For application elements, try to get the main window
            return element.mainWindow() ?? element
        }
        
        return nil
    }
    
    /// Find the value to use for text splitting - either from the target element or closest element with value
    private func findElementValueForSplitting(targetElement: AXUIElement, windowElement: AXUIElement) async -> (value: String, isBeforeTarget: Bool) {
        // First try to get value from the target element itself
        if let targetValue = targetElement.value(), !targetValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            print("AccessibilityParsingManager: Using target element's own value for splitting")
            return (targetValue, false) // Element's own value, so neither before nor after
        }
        
        // If target element has no value, traverse the accessibility hierarchy to find closest element with value
        return await traverseForClosestValue(from: targetElement, in: windowElement)
    }
    
    /// Traverse accessibility hierarchy to find the closest element with a value
    private func traverseForClosestValue(from targetElement: AXUIElement, in windowElement: AXUIElement) async -> (value: String, isBeforeTarget: Bool) {
        // Strategy: Expand outward from target element
        // 1. Check siblings before and after target
        // 2. Move up to parent and check its siblings
        // 3. Continue up the hierarchy until we find a value or reach the window
        
        return await expandSearchFromElement(targetElement)
    }
    
    /// Expand search outward from the target element level by level
    private func expandSearchFromElement(_ element: AXUIElement) async -> (value: String, isBeforeTarget: Bool) {
        var currentElement = element
        
        // Track the path we took to get here, so we know which direction elements are in
        var pathFromTarget: [AXUIElement] = [element]
        
        while true {
            // Check siblings of current element
            if let result = await checkSiblingsForValue(of: currentElement, pathFromTarget: pathFromTarget) {
                return result
            }
            
            // Move up to parent
            guard let parent = currentElement.parent() else {
                break
            }
            
            // Stop if we've reached the window or application level
            let parentRole = parent.role()
            if parentRole == kAXWindowRole || parentRole == "AXWindow" ||
               parentRole == kAXApplicationRole || parentRole == "AXApplication" {
                break
            }
            
            pathFromTarget.append(parent)
            currentElement = parent
        }
        
        return ("", false)
    }
    
    /// Check siblings of an element for values, determining their position relative to target
    private func checkSiblingsForValue(of element: AXUIElement, pathFromTarget: [AXUIElement]) async -> (value: String, isBeforeTarget: Bool)? {
        guard let parent = element.parent(),
              let siblings = parent.children() else {
            return nil
        }
        
        // Find the index of our element among its siblings
        guard let elementIndex = findElementIndexInArray(element, in: siblings) else {
            return nil
        }
        
        // Search siblings before our element (these are "before" the target)
        for i in stride(from: elementIndex - 1, through: 0, by: -1) {
            if let value = await searchElementAndChildrenForValue(siblings[i]) {
                print("AccessibilityParsingManager: Found preceding sibling with value")
                return (value, true) // Element is before target
            }
        }
        
        // Search siblings after our element (these are "after" the target)
        for i in (elementIndex + 1)..<siblings.count {
            if let value = await searchElementAndChildrenForValue(siblings[i]) {
                print("AccessibilityParsingManager: Found following sibling with value")
                return (value, false) // Element is after target
            }
        }
        
        return nil
    }
    
    /// Search an element and its descendants for a value (depth-first)
    private func searchElementAndChildrenForValue(_ element: AXUIElement) async -> String? {
        // Check the element itself first
        if let value = element.value(), !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return value
        }
        
        // Search children depth-first
        guard let children = element.children() else {
            return nil
        }
        
        for child in children {
            if let value = await searchElementAndChildrenForValue(child) {
                return value
            }
        }
        
        return nil
    }
    
    /// Find the index of an element in an array by comparing properties
    private func findElementIndexInArray(_ targetElement: AXUIElement, in elements: [AXUIElement]) -> Int? {
        let targetRole = targetElement.role()
        let targetTitle = targetElement.title()
        let targetValue = targetElement.value()
        let targetFrame = targetElement.frame()
        
        for (index, element) in elements.enumerated() {
            // Compare multiple properties to identify the same element
            let elementRole = element.role()
            let elementTitle = element.title()
            let elementValue = element.value()
            let elementFrame = element.frame()
            
            // Elements match if all comparable properties are equal
            let roleMatch = targetRole == elementRole
            let titleMatch = targetTitle == elementTitle
            let valueMatch = targetValue == elementValue
            let frameMatch = targetFrame == elementFrame
            
            if roleMatch && titleMatch && valueMatch && frameMatch {
                return index
            }
        }
        
        return nil
    }
    
    /// Split the full text around the element value
    private func splitTextAroundValue(fullText: String, elementValue: String, isElementBeforeTarget: Bool) -> (precedingText: String, followingText: String) {
        // Find the element value in the full text
        guard let range = fullText.range(of: elementValue) else {
            print("AccessibilityParsingManager: Element value '\(elementValue)' not found in full text")
            return ("", fullText)
        }
        
        let precedingText = String(fullText[..<range.lowerBound])
        let followingText = String(fullText[range.upperBound...])
        
        if isElementBeforeTarget {
            // Element value should be included with preceding text
            let adjustedPrecedingText = precedingText + elementValue
            return (adjustedPrecedingText, followingText)
        } else {
            // Element value should be included with following text
            let adjustedFollowingText = elementValue + followingText
            return (precedingText, adjustedFollowingText)
        }
    }
    
    /// Direct parsing method that bypasses the request system for simple cases
    func parseElement(_ windowElement: AXUIElement) async -> [String: String] {
        let elementHash = CFHash(windowElement)
        
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
        let elementHash = CFHash(windowElement)
        
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
