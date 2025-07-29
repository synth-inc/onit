//
//  ContextFetchingService.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/29/25.
//

import ApplicationServices
import Defaults
import Foundation
import PostHog
import SwiftUI

@MainActor
class ContextFetchingService {
    static let shared = ContextFetchingService()
    
    // MARK: - Properties
    
    private var timedOutWindowHash: Set<UInt> = []  // Track window's hash that have timed out
    private var lastActiveWindowPid: pid_t?
    
    // MARK: - Private initializer
    
    private init() { }
    
    // MARK: - Functions
    
    func retrieveWindowContent(
        pid: pid_t? = nil,
        state: OnitPanelState? = nil,
        trackedWindow: TrackedWindow? = nil,
        customAppBundleUrl: URL? = nil,
        lastActiveWindowPid: pid_t? = nil
    ) {
        guard let pid = trackedWindow?.pid ?? pid ?? lastActiveWindowPid,
              let mainWindow = trackedWindow?.element ?? pid.firstMainWindow,
              let state = state ?? PanelStateCoordinator.shared.getState(for: CFHash(mainWindow))
        else {
            return
        }
        
        let windowHash = trackedWindow?.hash ?? CFHash(mainWindow)
        
        state.windowContextTasks[windowHash]?.cancel()
        
        // This task will automatically be cleaned up way down the call stack when it hits `addAutoContext()`.
        state.windowContextTasks[windowHash] = Task {
            if let documentInfo = findDocument(in: mainWindow) {
                handleWindowContent(
                    documentInfo,
                    for: state,
                    trackedWindow: trackedWindow,
                    customAppBundleUrl: customAppBundleUrl
                )
                // TODO: KNA - uncomment this to use WebContentFetchService with AXURL
            } else if let url = findUrl(in: mainWindow), url.absoluteString.contains("docs.google.com") {
                
                let appName = mainWindow.parent()?.title() ?? ""
                let appTitle = mainWindow.title() ?? ""
                let startTime = CFAbsoluteTimeGetCurrent()
                if GoogleDriveService.shared.checkAuthorizationStatus() {
                    do {
                        let documentContent = try await GoogleDriveService.shared.extractTextFromGoogleDrive(driveUrl: url.absoluteString)
                        let contentArray = [
                            AccessibilityParsedElements.applicationName: appName,
                            AccessibilityParsedElements.applicationTitle: appTitle,
                            AccessibilityParsedElements.elapsedTime: "\(CFAbsoluteTimeGetCurrent() - startTime)",
                            "document": documentContent
                        ]
                        handleWindowContent(
                            contentArray,
                            for: state,
                            customAppBundleUrl: customAppBundleUrl
                        )
                    } catch {
                        // Handle error case by creating error context
                        var appBundleUrl = customAppBundleUrl
                        if appBundleUrl == nil {
                            if let pid = lastActiveWindowPid,
                            let app = NSRunningApplication(processIdentifier: pid) {
                                appBundleUrl = app.bundleURL
                            }
                        }
                        
                        let errorMessage: String
                        let errorCode: Int32
                        if let googleDriveError = error as? GoogleDriveServiceError {
                            errorMessage = googleDriveError.localizedDescription
                            switch googleDriveError {
                            case .notFound:
                                errorCode = 1501
                            default:
                                errorCode = 1500
                            }
                        } else {
                            errorMessage = "Failed to extract Google Drive document content: \(error.localizedDescription)"
                            errorCode = 1500
                        }
                        
                        // Create ScreenResult with error information
                        let screenResult = ScreenResult(
                            applicationName: appName,
                            applicationTitle: appTitle,
                            others: nil,
                            errorMessage: errorMessage,
                            errorCode: errorCode,
                            appBundleUrl: appBundleUrl
                        )
                        
                        // Call addAutoContext to handle the error case
                        state.addAutoContext(trackedWindow: trackedWindow, screenResult: screenResult)
                    }
                } else {
                    // This creates an error state for when google drive is not authorized
                    var appBundleUrl = customAppBundleUrl
                    if appBundleUrl == nil {
                        if let pid = lastActiveWindowPid,
                        let app = NSRunningApplication(processIdentifier: pid) {
                            appBundleUrl = app.bundleURL
                        }
                    }
                    
                    // Create ScreenResult with unauthorized error
                    let screenResult = ScreenResult(
                        applicationName: appName,
                        applicationTitle: appTitle,
                        others: nil,
                        errorMessage: "Google Drive Plugin Required",
                        errorCode: 1500,
                        appBundleUrl: appBundleUrl
                    )
                    
                    // Call addAutoContext to handle the error case
                    state.addAutoContext(trackedWindow: trackedWindow, screenResult: screenResult)
                }
            }  else {
                parseAccessibility(
                    for: pid,
                    in: mainWindow,
                    state: state,
                    trackedWindow: trackedWindow,
                    customAppBundleUrl: customAppBundleUrl
                )
            }
        }
    }
    
    private func findDocument(in focusedWindow: AXUIElement) -> [String: String]? {
        let startTime = CFAbsoluteTimeGetCurrent()
        var documentValue: CFTypeRef?
        
        let hasDocument = AXUIElementCopyAttributeValue(focusedWindow, kAXDocumentAttribute as CFString, &documentValue) == .success
        
        if hasDocument, let document = documentValue as? String,
            document.hasPrefix("file:///"), let fileURL = URL(string: document) {
            do {
                let appName = focusedWindow.parent()?.title() ?? ""
                let appTitle = focusedWindow.title() ?? ""
                let content = try String(contentsOf: fileURL, encoding: .utf8)
                
                return [
                    AccessibilityParsedElements.applicationName: appName,
                    AccessibilityParsedElements.applicationTitle: appTitle,
                    AccessibilityParsedElements.elapsedTime: "\(CFAbsoluteTimeGetCurrent() - startTime)",
                    "document": content
                ]
            } catch {
                return nil
            }
        }
        
        return nil
    }
    
    private func findUrl(in element: AXUIElement, maxDepth: Int = 5) -> URL? {
        func findURLInChildren(element: AXUIElement, depth: Int = 0) -> URL? {
            if depth >= maxDepth {
                return nil
            }
            
            if let children = element.children() {
                for child in children {
                    if child.role() == "AXWebArea", let url = child.url() {
                        return url
                    }
                    
                    if let url = findURLInChildren(element: child, depth: depth + 1) {
                        return url
                    }
                }
            }
            
            return nil
        }
        return findURLInChildren(element: element)
    }
    
    private func findUrlAndProcessURL(in focusedWindow: AXUIElement) async -> [String: String]? {
        let startTime = CFAbsoluteTimeGetCurrent()
        
        func processUrl(_ url: URL, from element: AXUIElement) async -> [String: String]? {
            do {
                let appName = element.parent()?.title() ?? ""
                let appTitle = element.title() ?? ""
                
                let (_, content) = try await WebContentFetchService.fetchWebpageContent(websiteUrl: url)
                
                return [
                    AccessibilityParsedElements.applicationName: appName,
                    AccessibilityParsedElements.applicationTitle: appTitle,
                    AccessibilityParsedElements.elapsedTime: "\(CFAbsoluteTimeGetCurrent() - startTime)",
                    "url": url.absoluteString,
                    "content": content
                ]
            } catch {
                print("Error processing URL: \(error)")
                return nil
            }
        }
        
        if let url = findUrl(in: focusedWindow) {
            return await processUrl(url, from: focusedWindow)
        }
        
        return nil
    }
    
    private func parseAccessibility(
        for pid: pid_t,
        in window: AXUIElement,
        state: OnitPanelState,
        trackedWindow: TrackedWindow? = nil,
        customAppBundleUrl: URL? = nil
    ) {
        let windowHash = trackedWindow?.hash ?? CFHash(window)
        let appName = trackedWindow?.element.parent()?.title() ?? window.parent()?.title() ?? "Unknown"
        let mainWindow = trackedWindow?.element ?? window
        
        if timedOutWindowHash.contains(windowHash) {
            print("Skipping parsing for window's hash \(windowHash) due to previous timeout.")
            return
        }
        
        guard Defaults[.autoContextFromCurrentWindow] else {
            return
        }
        
        // Note: The original implementation used a debounce interval, but it's not needed here
        // since we're not implementing the debouncing logic in this service
        
        Task {
            do {
                let (results, boundingBoxes) = try await AccessibilityParser.shared.getAllTextInElement(windowElement: mainWindow)
                handleWindowContent(
                    results,
                    for: state,
                    trackedWindow: trackedWindow,
                    customAppBundleUrl: customAppBundleUrl
                )
            } catch {
                await MainActor.run {
                    print("Accessibility timeout")
                    self.timedOutWindowHash.insert(windowHash)
                    AnalyticsManager.Accessibility.parseTimedOut(appName: appName)
                    
                    // Create ScreenResult with timeout error
                    let screenResult = ScreenResult(
                        applicationName: appName,
                        applicationTitle: "",
                        others: nil,
                        errorMessage: "Timeout occurred, could not read application in reasonable amount of time.",
                        errorCode: 1500,
                        appBundleUrl: nil
                    )
                    
                    // Call addAutoContext to handle the error case
                    state.addAutoContext(trackedWindow: trackedWindow, screenResult: screenResult)
                }
            }
        }
    }
    
    private func handleWindowContent(
        _ results: [String: String]?,
        for state: OnitPanelState,
        trackedWindow: TrackedWindow? = nil,
        customAppBundleUrl: URL? = nil
    ) {
        var appBundleUrl: URL? = customAppBundleUrl
        
        if appBundleUrl == nil,
           let pid = lastActiveWindowPid,
           let app = NSRunningApplication(processIdentifier: pid)
        {
            appBundleUrl = app.bundleURL
        }
        
        let appName = results?[AccessibilityParsedElements.applicationName] ?? ""
        let appTitle = results?[AccessibilityParsedElements.applicationTitle] ?? ""
        
        // Create ScreenResult object
        let screenResult = ScreenResult(
            applicationName: appName,
            applicationTitle: appTitle,
            others: results,
            errorMessage: nil,
            errorCode: nil,
            appBundleUrl: appBundleUrl
        )
        
        // Call addAutoContext to handle the context creation and cleanup
        state.addAutoContext(trackedWindow: trackedWindow, screenResult: screenResult)
    }
    
    func reset() {
        /// I (Kevin) don't think we should reset the timed out windows
        // timedOutWindowHash.removeAll()
        lastActiveWindowPid = nil
    }
    
    // MARK: - Debug
    
    private func showDebug() {
        // Debug information is now handled by individual ScreenResult objects
        DebugManager.shared.debugText = "Context fetching using ScreenResult objects"
    }
}
