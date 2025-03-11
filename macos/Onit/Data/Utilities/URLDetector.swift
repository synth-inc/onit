//
//  URLDetector.swift
//  Onit
//
//  Created by OpenHands on 3/11/2024.
//

import Foundation

class URLDetector {
    
    /// Detects URLs in the given text
    /// - Parameter text: The text to search for URLs
    /// - Returns: An array of detected URLs
    static func detectURLs(in text: String) -> [URL] {
        // Define a regex pattern for URLs
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []
        
        return matches.compactMap { match -> URL? in
            if let url = match.url, isValidURL(url) {
                return url
            }
            return nil
        }
    }
    
    /// Checks if a URL is valid for scraping
    /// - Parameter url: The URL to validate
    /// - Returns: Boolean indicating if the URL is valid
    private static func isValidURL(_ url: URL) -> Bool {
        // Check if the URL has a scheme (http or https)
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }
    
    /// Scrapes content from a URL
    /// - Parameter url: The URL to scrape
    /// - Returns: The scraped text content
    static func scrapeContent(from url: URL) async throws -> String {
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Try to determine the text encoding from the response
        var encoding = String.Encoding.utf8
        
        if let encodingName = httpResponse.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(encodingName as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
            }
        }
        
        // Try to convert the data to a string
        if let content = String(data: data, encoding: encoding) {
            // Extract text content from HTML
            return extractTextFromHTML(content)
        } else {
            throw URLError(.cannotDecodeContentData)
        }
    }
    
    /// Extracts text content from HTML
    /// - Parameter html: The HTML string
    /// - Returns: Plain text extracted from HTML
    private static func extractTextFromHTML(_ html: String) -> String {
        // Simple HTML tag removal - for a production app, consider using a proper HTML parser
        var text = html
        
        // Remove script and style elements
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)
        
        // Remove HTML comments
        text = text.replacingOccurrences(of: "<!--[\\s\\S]*?-->", with: "", options: .regularExpression)
        
        // Replace HTML tags with newlines for better readability
        text = text.replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
        
        // Replace multiple newlines with a single newline
        text = text.replacingOccurrences(of: "\n+", with: "\n", options: .regularExpression)
        
        // Decode HTML entities
        text = text.decodingHTMLEntities()
        
        // Trim whitespace
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return text
    }
}

extension String {
    /// Decodes HTML entities in a string
    func decodingHTMLEntities() -> String {
        guard let data = self.data(using: .utf8) else { return self }
        
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        
        if let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributedString.string
        }
        
        return self
    }
}