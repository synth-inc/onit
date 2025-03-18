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
            let urlHost = url.host ?? "URL"
            
            // Check for duplicates on the main actor
            let isDuplicate = await MainActor.run {
                model.pendingContextList.contains { context in
                    if case .webAuto(let appName, _, _) = context {
                        return appName == "Web: \(urlHost)"
                    }
                    if case .auto(let appName, _) = context {
                        return appName == "Web: \(urlHost)"
                    }
                    return false
                }
            }
            
            if isDuplicate {
                continue
            }
            
            await MainActor.run {
                model.pendingContextList.append(.loading(urlHost))
            }
            
            do {
                // Show loading indicator or feedback
                // You could add a loading indicator here if needed
                
                // Scrape content from the URL
                let result = try await URLDetector.scrapeContentAndMetadata(from: url)
                let truncatedContent = result.content.count > maxContentLength
                    ? String(result.content.prefix(maxContentLength)) + "\n[Content truncated due to length...]"
                    : result.content
                
                // Create a context with the web content
                await MainActor.run {
                    // Remove loading context
                    model.pendingContextList.removeAll { context in
                        if case .loading(let host) = context {
                            return host == urlHost
                        }
                        return false
                    }
                    
                    // Add web context with structured content and index
                    let webContext = Context.webAuto(
                        "Web: \(urlHost)",
                        [
                            "url": url.absoluteString,
                            "title": result.title ?? urlHost,
                            "content": truncatedContent,
                            // Add index to maintain order
                            "index": String(index),
                            // Add domain for better identification
                            "domain": urlHost
                        ],
                        result.asWebMetadata
                    )
                    model.pendingContextList.append(webContext)
                }
            } catch {
                await MainActor.run {
                    // Remove loading context
                    model.pendingContextList.removeAll { context in
                        if case .loading(let host) = context {
                            return host == urlHost
                        }
                        return false
                    }
                }
                print("Error scraping content from URL: \(error.localizedDescription)")
                // You could add error handling UI here if needed
            }
        }
        
        // Remove URLs from the text to avoid duplication
        var processedText = text
        for url in urls {
            processedText = processedText.replacingOccurrences(of: url.absoluteString, with: "")
        }
        
        // Clean up any double spaces or newlines that might have been created
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
