//
//  WebContentContext.swift
//  Onit
//
//  Created by OpenHands on 3/11/2024.
//

import Foundation
import SwiftUI

/// A class to handle web content scraping and context creation
class WebContentContext {
    
    /// Maximum length of web content to include in context
    private static let maxContentLength = 10000
    
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
        for url in urls {
            do {
                // Show loading indicator or feedback
                await MainActor.run {
                    // You could add a loading indicator here if needed
                }
                
                // Scrape content from the URL
                let content = try await URLDetector.scrapeContent(from: url)
                
                // Truncate content if it's too long
                let truncatedContent = content.count > maxContentLength 
                    ? String(content.prefix(maxContentLength)) + "\n[Content truncated due to length...]" 
                    : content
                
                // Create a context with the web content
                await MainActor.run {
                    let webContext = Context.auto("Web: \(url.host ?? "URL")", ["content": truncatedContent])
                    model.pendingContextList.append(webContext)
                }
            } catch {
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