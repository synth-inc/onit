//
//  WebContentContext.swift
//  Onit
//
//  Created by Loyd Kim on 3/11/2024.
//

import Foundation
import SwiftUI

/// A class to handle web content scraping and context creation
@MainActor
class WebContentContext {
    
    /// Maximum length of web content to include in context
    internal static let maxContentLength = 10000
    
    private struct LoadingIdentifier: Hashable {
        let url: URL
        let host: String
        let id: UUID
        
        init(url: URL) {
            self.url = url
            self.host = url.host ?? "URL"
            self.id = UUID()
        }
    }
    
    /// Processes text input to detect URLs and create context from web content
    /// - Parameters:
    ///   - text: The text input that may contain URLs
    ///   - model: The Onit model to update with context
    /// - Returns: A tuple containing the processed text (with URL removed) and a boolean indicating if URLs were found
    static func processTextForURLs(text: String, model: OnitModel) async -> (processedText: String, foundURLs: Bool) {
        // Detect URLs in the text
        let urls = URLDetector.detectURLs(in: text)
        
        guard !urls.isEmpty else {
            return (text, false)
        }
        
        // Process each URL
        for (index, url) in urls.enumerated() {
            let loadingIdentifier = LoadingIdentifier(url: url)
            
            // Check for duplicates on the main actor
            let isDuplicate = await MainActor.run {
                model.pendingContextList.contains { context in
                    if case .webAuto(let appName, _, _) = context {
                        return appName == "Web: \(loadingIdentifier.host)"
                    }
                    if case .auto(let appName, _) = context {
                        return appName == "Web: \(loadingIdentifier.host)"
                    }
                    return false
                }
            }
            
            if isDuplicate {
                continue
            }
            
            await MainActor.run {
                model.pendingContextList.append(.loading("\(loadingIdentifier.host):\(loadingIdentifier.id)"))
            }
            
            do {
                // Show loading indicator or feedback
                // You could add a loading indicator here if needed
                
                // Scrape content from the URL
                let result = try await URLDetector.scrapeContentAndMetadata(from: url)
                let content = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip if content is empty or just whitespace
                guard !content.isEmpty else {
                    await MainActor.run {
                        // Remove loading context
                        model.pendingContextList.removeAll { context in
                            if case .loading(let identifier) = context {
                                return identifier == "\(loadingIdentifier.host):\(loadingIdentifier.id)"
                            }
                            return false
                        }
                        
                        // Add empty content error context
                        let errorContext = Context.webAuto(
                            "Web: \(loadingIdentifier.host)",
                            [
                                "url": url.absoluteString,
                                "title": "No content found",
                                "content": "The page appears to be empty or contains no meaningful content.",
                                "index": String(index),
                                "domain": loadingIdentifier.host,
                                "error": "true",
                                "requestId": loadingIdentifier.id.uuidString
                            ],
                            WebMetadata(title: "No content found", faviconImageData: nil)
                        )
                        model.pendingContextList.append(errorContext)
                    }
                    continue
                }
                
                let truncatedContent = content.count > maxContentLength
                    ? String(content.prefix(maxContentLength)) + "\n[Content truncated due to length...]"
                    : content
                
                // Create a context with the web content
                await MainActor.run {
                    // Remove loading context
                    model.pendingContextList.removeAll { context in
                        if case .loading(let identifier) = context {
                            return identifier == "\(loadingIdentifier.host):\(loadingIdentifier.id)"
                        }
                        return false
                    }
                    
                    // Add web context with structured content and index
                    let webContext = Context.webAuto(
                        "Web: \(loadingIdentifier.host)",
                        [
                            "url": url.absoluteString,
                            "title": result.title ?? loadingIdentifier.host,
                            "content": truncatedContent,
                            "index": String(index),
                            "domain": loadingIdentifier.host,
                            "requestId": loadingIdentifier.id.uuidString  // Store the request ID for reference
                        ],
                        result.asWebMetadata
                    )
                    model.pendingContextList.append(webContext)
                }
            } catch {
                await MainActor.run {
                    // Remove loading context
                    model.pendingContextList.removeAll { context in
                        if case .loading(let identifier) = context {
                            return identifier == "\(loadingIdentifier.host):\(loadingIdentifier.id)"
                        }
                        return false
                    }
                    
                    // Add error context instead of just printing to console
                    let errorContext = Context.webAuto(
                        "Web: \(loadingIdentifier.host)",
                        [
                            "url": url.absoluteString,
                            "title": "Error loading content",
                            "content": "Failed to load content: \(error.localizedDescription)",
                            "index": String(index),
                            "domain": loadingIdentifier.host,
                            "error": "true",
                            "requestId": loadingIdentifier.id.uuidString  // Store the request ID for reference
                        ],
                        WebMetadata(title: "Error loading content", faviconImageData: nil)
                    )
                    model.pendingContextList.append(errorContext)
                }
            }
        }
        
        // Replace URLs with placeholders to maintain sentence context
        var processedText = text
        for (index, url) in urls.enumerated() {
            let placeholder = "[Link \(index + 1)]"
            processedText = processedText.replacingOccurrences(of: url.absoluteString, with: placeholder)
        }
        
        // Clean up any double spaces or newlines
        processedText = processedText.replacingOccurrences(of: "  ", with: " ")
        processedText = processedText.replacingOccurrences(of: "\n\n", with: "\n")
        processedText = processedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return (processedText, true)
    }
}

struct WebContentAndMetadata: Sendable {
    let content: String
    let title: String?
    let faviconImageData: Data?
    
    var asWebMetadata: WebMetadata {
        WebMetadata(title: title, faviconImageData: faviconImageData)
    }
}
