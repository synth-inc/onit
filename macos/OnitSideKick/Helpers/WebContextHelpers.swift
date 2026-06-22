//
//  WebContextHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 3/27/25.
//

import Foundation

func detectURLs(in text: String) -> [URL] {
    guard let detectUrlRegex = try? NSRegularExpression(
        pattern: "https?://(?:www\\.|(?!www))[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|www\\.[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]\\.[^\\s]{2,}|https?://(?:www\\.|(?!www))[a-zA-Z0-9]+\\.[^\\s]{2,}|www\\.[a-zA-Z0-9]+\\.[^\\s]{2,}",
        options: .caseInsensitive
    ) else {
        return []
    }
    
    let urlMatches = detectUrlRegex.matches(
        in: text,
        options: [],
        range: NSRange(location: 0, length: text.utf16.count)
    )
    
    let detectedURLs = urlMatches.compactMap { match -> URL? in
        if let range = Range(match.range, in: text) {
            let urlString = String(text[range])
            // Add https:// to www. URLs that don't have a scheme
            let fixedURLString = urlString.hasPrefix("www.") && !urlString.hasPrefix("http")
                ? "https://" + urlString
                : urlString
            return URL(string: fixedURLString)
        }
        return nil
    }
    
    // Remove duplicate links. Not using Set<URL> here, because we want to preserve the links in the order they appear in chat.
    return detectedURLs.reduce(into: [URL]()) { uniqueURLs, url in
        if !uniqueURLs.contains(url) {
            uniqueURLs.append(url)
        }
    }
}

func removeWebsiteUrlFromText(text: String, websiteUrl: URL) -> String {
    var textInputWithoutUrls = text.replacingOccurrences(
        of: websiteUrl.absoluteString,
        with: ""
    )
    
    // After the scraped website URL, this regex cleans up any extra spaces.
    let multipleSpacesRegex = "\\s{2,}"
    if let regex = try? NSRegularExpression(pattern: multipleSpacesRegex, options: []) {
        let regexRange = NSRange(location: 0, length: textInputWithoutUrls.count)
        let replacementString = " "
        
        textInputWithoutUrls = regex.stringByReplacingMatches(
            in: textInputWithoutUrls,
            options: [],
            range: regexRange,
            withTemplate: replacementString
        )
    }

    textInputWithoutUrls = textInputWithoutUrls.trimmingCharacters(in: .whitespacesAndNewlines)
    
    return textInputWithoutUrls
}

/// Known second-level country-code domains.
private let knownSecondLevelCountryCodeDomains: Set<String> = ["co.uk","co.jp", "co.kr", "co.in", "co.nz", "co.za", "co.id", "co.th", "com.au", "com.br", "com.mx", "com.tr", "com.sg", "com.ar", "com.tw", "com.hk", "com.my", "com.ph", "com.pk", "com.co", "com.ng", "com.eg", "com.vn", "com.ua", "com.sa", "com.pe", "com.bd", "org.uk", "net.au", "net.br", "ne.jp", "or.jp", "ac.uk", "ac.jp"]

func getWebPlatformName(from urlString: String) -> String? {
    let safeUrlString = urlString.lowercased()

    let normalizedString: String

    if safeUrlString.hasPrefix("http://") || safeUrlString.hasPrefix("https://") {
        normalizedString = safeUrlString
    } else {
        normalizedString = "https://\(safeUrlString)"
    }

    guard let url = URL(string: normalizedString),
          let urlHost = url.host?.lowercased()
    else {
        return nil
    }

    let normalizedUrlHost = urlHost.hasPrefix("www.") ? String(urlHost.dropFirst(4)) : urlHost

    let normalizedUrlHostParts = normalizedUrlHost.split(separator: ".").map(String.init)
    
    guard normalizedUrlHostParts.count >= 2
    else {
        return normalizedUrlHostParts.first
    }

    /// Checking for potential country-code domains (e.g. `co.uk`, `co.au`, etc.).
    let lastTwoHostParts = "\(normalizedUrlHostParts[normalizedUrlHostParts.count - 2]).\(normalizedUrlHostParts.last!)"

    if knownSecondLevelCountryCodeDomains.contains(lastTwoHostParts),
       normalizedUrlHostParts.count >= 3
    {
        return normalizedUrlHostParts[normalizedUrlHostParts.count - 3]
    }

    return normalizedUrlHostParts[normalizedUrlHostParts.count - 2]
}

func getWebContextItemIndex(pendingContextList: [Context], comparativeWebUrl: URL) -> Int? {
    if let webContextIndex = pendingContextList.firstIndex(where: { context in
        switch context {
        case .web (let existingWebsiteUrl, _, _):
            return existingWebsiteUrl == comparativeWebUrl
        default:
            return false
        }
    }) {
        return webContextIndex
    } else {
        return nil
    }
}
