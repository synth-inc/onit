//
//  StringHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 7/18/25.
//

import Foundation

struct StringHelpers {
    static func removeWhiteSpaceAndNewLines(_ str: String) -> String {
        return str.replacingOccurrences(of: "\\r?\\n", with: " ", options: .regularExpression)
            .replacingOccurrences(of: " +", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    static func lastNWords(_ text: String, count: Int) -> String {
        let words = text.split(separator: " ")
        if words.count > count {
            return words.suffix(count).joined(separator: " ")
        } else {
            return text
        }
    }
    
    static func addSpacesBetweenCharacters(_ text: String) -> String {
        return text.map(String.init).joined(separator: " ")
    }
    
    private static let websiteUrlSchemes = ["http", "https"]
    
    static func convertStringToWebsiteUrl(_ rawUrlString: String) -> URL? {
        /// Swift's reliable built-in pattern detector for many things, links included. Allows us to extract a URL from text.
        if let detector = try? NSDataDetector(
            types: NSTextCheckingResult.CheckingType.link.rawValue
        ) {
            let range = NSRange(
                rawUrlString.startIndex..<rawUrlString.endIndex,
                in: rawUrlString
            )
            
            if let urlMatch = detector.firstMatch(
                in: rawUrlString,
                options: [],
                range: range
            ),
               let websiteUrl = urlMatch.url,
               let websiteUrlScheme = websiteUrl.scheme?.lowercased(),
               Self.websiteUrlSchemes.contains(websiteUrlScheme), /// Checking the "http(s)" portion.
               websiteUrl.host != nil /// Checking the host (e.g. "google.com").
            {
                return websiteUrl
            }
        }
        
        /// Fallback.
        if var urlComponents = URLComponents(string: rawUrlString) {
            /// Manually add a scheme if the provided `urlString` doesn't have one.
            /// Required, as `urlComponents.url` won't produce a valid URL otherwise.
            if urlComponents.scheme == nil {
                urlComponents.scheme = "https"
            }
            
            if let websiteUrl = urlComponents.url,
               let websiteUrlScheme = urlComponents.scheme?.lowercased(),
               Self.websiteUrlSchemes.contains(websiteUrlScheme), /// Checking the "http(s)" portion.
               websiteUrl.host != nil /// Checking the host (e.g. "google.com").
            {
                return websiteUrl
            }
        }

        return nil
    }
    
    static func checkStringIsValidWebsiteUrl(_ urlString: String) -> Bool {
        guard let websiteUrl = Self.convertStringToWebsiteUrl(urlString)
        else {
            return false
        }
        
        return Self.websiteUrlSchemes.contains(websiteUrl.scheme?.lowercased() ?? "")
    }
    
    static func stripOnlyHostAndPathFromWebsiteUrl(
        _ rawUrlString: String,
        removeSensitiveInformation: Bool = true,
        removeQuery: Bool = false,
        removeWWW: Bool = true,
        decodePercentEncoding: Bool = true
    ) -> String? {
        guard let websiteUrl = Self.convertStringToWebsiteUrl(rawUrlString),
              var urlComponents = URLComponents(url: websiteUrl, resolvingAgainstBaseURL: false)
        else {
            return nil
        }
        
        urlComponents.scheme = nil
        
        if removeSensitiveInformation {
            urlComponents.user = nil
            urlComponents.password = nil
        }
        
        if removeQuery {
            urlComponents.query = nil
        }
        
        var websiteUrlString = urlComponents.string
            ?? websiteUrl.host
            ?? rawUrlString
        
        if websiteUrlString.hasPrefix("//") {
            websiteUrlString.removeFirst(2)
        }
        
        if removeWWW,
           websiteUrlString.hasPrefix("www.")
        {
            websiteUrlString.removeFirst(4)
        }
        
        /// Converts percent escapes to their character equivalents. For example, `%40` → `@`.
        if decodePercentEncoding {
            return websiteUrlString.removingPercentEncoding ?? websiteUrlString
        } else {
            return websiteUrlString
        }
    }
}
