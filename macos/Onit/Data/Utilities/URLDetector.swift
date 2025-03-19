//
//  URLDetector.swift
//  Onit
//
//  Created by Loyd Kim on 3/11/2024.
//

import Foundation
import LinkPresentation
import UniformTypeIdentifiers
import AppKit

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
    
    /// Scrapes metadata from a URL
    /// - Parameter url: The URL to scrape
    /// - Returns: A tuple of content and metadata
    static func scrapeContentAndMetadata(from url: URL) async throws -> WebContentAndMetadata {
        // First get the content
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        // Detect the correct encoding
        let encoding = detectEncoding(from: httpResponse, data: data)
        
        // Get content with detected encoding
        let content = extractTextFromHTML(data: data, encoding: encoding)
        
        // Use LinkPresentation for metadata
        let provider = LPMetadataProvider()
        let lpMetadata = try await provider.startFetchingMetadata(for: url)
        
        // Get the icon data with better error handling
        var faviconImageData: Data? = nil
        if let iconProvider = lpMetadata.iconProvider {
            do {
                if let loadedItem = try? await iconProvider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) {
                    if let nsImage = loadedItem as? NSImage {
                        // We got an NSImage directly
                        if let tiffData = nsImage.tiffRepresentation,
                           let bitmap = NSBitmapImageRep(data: tiffData),
                           let pngData = bitmap.representation(using: .png, properties: [:]) {
                            faviconImageData = pngData
                        }
                    } else if let imageData = loadedItem as? Data {
                        // We got raw data, try to create an image from it
                        if let nsImage = NSImage(data: imageData) {
                            // Convert to PNG for consistency
                            if let tiffData = nsImage.tiffRepresentation,
                               let bitmap = NSBitmapImageRep(data: tiffData),
                               let pngData = bitmap.representation(using: .png, properties: [:]) {
                                faviconImageData = pngData
                            }
                        }
                    }
                }
            } catch {
                // Silently fail, will use fallback icon
            }
        }
        
        // If still no icon, try the default favicon.ico
        if faviconImageData == nil {
            do {
                let faviconURL = url.deletingLastPathComponent().appendingPathComponent("favicon.ico")
                let (data, response) = try await URLSession.shared.data(from: faviconURL)
                
                if let httpResponse = response as? HTTPURLResponse,
                   (200...299).contains(httpResponse.statusCode),
                   let image = NSImage(data: data),
                   let tiffData = image.tiffRepresentation,
                   let bitmap = NSBitmapImageRep(data: tiffData),
                   let pngData = bitmap.representation(using: .png, properties: [:]) {
                    faviconImageData = pngData
                }
            } catch {
                print("Error fetching favicon.ico: \(error)")
            }
        }
        
        return WebContentAndMetadata(
            content: content,
            title: lpMetadata.title,
            faviconImageData: faviconImageData
        )
    }
    
    private static func extractTitle(from html: String) -> String? {
        // First try standard title tag with lookahead/lookbehind
        let titlePattern = "(?<=<title[^>]*>)([^<]+)(?=</title>)"
        if let range = html.range(of: titlePattern, options: .regularExpression) {
            let title = String(html[range])
            let decodedTitle = title.decodingHTMLEntities()
            return decodedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Try Open Graph title as fallback with lookahead/lookbehind
        let ogPattern = "(?<=<meta[^>]+property=\"og:title\"[^>]+content=\")[^\"]+(?=\")"
        if let range = html.range(of: ogPattern, options: .regularExpression) {
            let title = String(html[range])
            let decodedTitle = title.decodingHTMLEntities()
            return decodedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        return nil
    }
    
    private static func getFaviconURL(for url: URL, from html: String) async throws -> URL? {
        // Try to find favicon in HTML with multiple patterns using lookahead/lookbehind
        let faviconPatterns = [
            // Apple touch icon with lookahead/lookbehind
            "(?<=<link[^>]*rel=\"apple-touch-icon\"[^>]*href=\")[^\"]+(?=\")",
            // Standard favicon with lookahead/lookbehind
            "(?<=<link[^>]*rel=\"(?:shortcut )?icon\"[^>]*href=\")[^\"]+(?=\")",
            // Open Graph image with lookahead/lookbehind
            "(?<=<meta[^>]+property=\"og:image\"[^>]+content=\")[^\"]+(?=\")"
        ]
        
        for pattern in faviconPatterns {
            if let range = html.range(of: pattern, options: .regularExpression) {
                let path = String(html[range])
                if let faviconURL = URL(string: path, relativeTo: url)?.absoluteURL {
                    // Verify the URL is accessible
                    do {
                        let (_, response) = try await URLSession.shared.data(from: faviconURL)
                        if let httpResponse = response as? HTTPURLResponse,
                           (200...299).contains(httpResponse.statusCode) {
                            return faviconURL
                        }
                    } catch {
                        continue
                    }
                }
            }
        }
        
        // Try default favicon.ico location as last resort
        let defaultFaviconURL = url.deletingLastPathComponent().appendingPathComponent("favicon.ico")
        do {
            let (_, response) = try await URLSession.shared.data(from: defaultFaviconURL)
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                return defaultFaviconURL
            }
        } catch {
            return nil
        }
        
        return nil
    }

    // Detects the character encoding from HTTP response and HTML content
    // - Parameters:
    //   - response: The HTTP response
    //   - data: The raw data
    // - Returns: The detected encoding
    private static func detectEncoding(from response: HTTPURLResponse, data: Data) -> String.Encoding {
        // First try the HTTP Content-Type header
        if let textEncodingName = response.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(textEncodingName as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
                return encoding
            }
        }
        
        // Try to detect from HTML meta tags
        if let htmlString = String(data: data, encoding: .isoLatin1) {
            // Look for charset in meta tags
            let metaPattern = "<meta[^>]+charset=['\"]?([^'\"\\s/>]+)['\"]?"
            if let range = htmlString.range(of: metaPattern, options: .regularExpression),
               let charsetRange = htmlString[range].range(of: "charset=['\"]?([^'\"\\s/>]+)['\"]?", options: .regularExpression) {
                let charset = htmlString[charsetRange]
                    .replacingOccurrences(of: "charset=", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "['\"]", with: "", options: .regularExpression)
                
                let cfEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
                if cfEncoding != kCFStringEncodingInvalidId {
                    let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
                    return encoding
                }
            }
        }
        
        // Fall back to UTF-8
        return .utf8
    }
    
    // Extracts text content from HTML data using the detected encoding
    // - Parameters:
    //   - data: The raw data
    //   - encoding: The character encoding to use
    // - Returns: Plain text extracted from HTML
    private static func extractTextFromHTML(data: Data, encoding: String.Encoding) -> String {
        // Try to create string with detected encoding
        guard let html = String(data: data, encoding: encoding) ?? String(data: data, encoding: .isoLatin1) else {
            return ""
        }
        
        // Remove script and style elements
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
    
    // Extracts text content from HTML
    // - Parameter html: The HTML string
    // - Returns: Plain text extracted from HTML
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
    // Decodes HTML entities in a string
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
