//
//  Context.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import AppKit
import Foundation

struct AutoContext: Codable, Hashable {
    let appName: String
    let appHash: UInt
    let appTitle: String
    let appContent: [String: String]
    let appBundleUrl: URL?
}

enum Context {
    case auto(AutoContext)
    case file(URL)
    case image(URL)
    case tooBig(URL)
    case error(URL, Error)
    case webSearch(String, String, String, URL?)
    
    typealias WebsiteUrl = URL
    typealias WebsiteTitle = String
    typealias WebsiteFileUrl = URL?
    case web (WebsiteUrl,  WebsiteTitle, WebsiteFileUrl)

    static let maxFileSize: Int = 1024 * 1024 * 1
    static let maxImageSize: Int = 1024 * 1024 * 20

    var url: URL? {
        switch self {
        case .auto:
            return nil
        case .file(let url), .image(let url), .tooBig(let url), .error(let url, _):
            return url
        case .webSearch(_, _, _, let url):
            return url
        case .web(_, _, let webFileUrl):
            return webFileUrl
        }
    }

    var fileType: String? {
        switch self {
        case .auto:
            "Auto"
        case .file:
            "file"
        case .image:
            "Img"
        case .webSearch:
            "WebSearch"
        case .web:
            "Web"
        default:
            nil
        }
    }

    var isAutoContext: Bool {
        switch self {
        case .auto:
            return true
        default:
            return false
        }
    }
    
    var isWebSearchContext: Bool {
        switch self {
        case .webSearch:
            return true
        default:
            return false
        }
    }

    var webURL: URL? {
        switch self {
        case .webSearch(_, _, _, let url):
            return url
        default:
            return nil
        }
    }
}

extension Context {
    init(
        appName: String,
        appHash: UInt,
        appTitle: String,
        appContent: [String: String],
        appBundleUrl: URL? = nil
    ) {
        self = .auto(
            AutoContext(
                appName: appName,
                appHash: appHash,
                appTitle: appTitle,
                appContent: appContent,
                appBundleUrl: appBundleUrl
            )
        )
    }
    
    init(title: String, content: String, source: String, url: URL? = nil) {
        self = .webSearch(title, content, source, url)
    }

    init(url: URL) {
        // Initialization for web context urls.
        if (url.scheme == "http" || url.scheme == "https") && url.host != nil {
            let websiteTitle = url.host() ?? url.absoluteString
            self = .web(url, websiteTitle, nil)
            return
        }
        
        // Initialization for non-web-context urls.
        do {
            let size = try url.size
            if url.isImage {
                self = size < Self.maxImageSize ? .image(url) : .tooBig(url)
            } else if size > Self.maxFileSize {
                self = .tooBig(url)
            } else {
                self = .file(url)
            }
        } catch {
            self = .error(url, error)
        }
    }
    
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

extension Context: Codable {
    enum CodingKeys: String, CodingKey {
        case autoContext, type, url, error, websiteUrl, websiteTitle, title, content, source
    }
    enum ContextType: String, Codable {
        case auto, file, image, tooBig, error, web, webSearch
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContextType.self, forKey: .type)

        switch type {
        case .auto:
            let autoContext = try container.decode(AutoContext.self, forKey: .autoContext)
            self = .auto(autoContext)
        case .file:
            let url = try container.decode(URL.self, forKey: .url)
            self = .file(url)
        case .image:
            let url = try container.decode(URL.self, forKey: .url)
            self = .image(url)
        case .tooBig:
            let url = try container.decode(URL.self, forKey: .url)
            self = .tooBig(url)
        case .error:
            let url = try container.decode(URL.self, forKey: .url)
            let errorDescription = try container.decode(String.self, forKey: .error)
            let error = NSError(
                domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            self = .error(url, error)
        case .webSearch:
            let title = try container.decode(String.self, forKey: .title)
            let content = try container.decode(String.self, forKey: .content)
            let source = try container.decode(String.self, forKey: .source)
            let url = try container.decodeIfPresent(URL.self, forKey: .url)
            self = .webSearch(title, content, source, url)
        case .web:
            let websiteUrl = try container.decode(URL.self, forKey: .websiteUrl)
            let websiteTitle = try container.decode(String.self, forKey: .websiteTitle)
            let webFileUrl = try container.decodeIfPresent(URL.self, forKey: .url)
            self = .web(websiteUrl, websiteTitle, webFileUrl)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .auto(let autoContext):
            try container.encode(autoContext, forKey: .autoContext)
            try container.encode(ContextType.auto, forKey: .type)
        case .file(let url):
            try container.encode(url, forKey: .url)
            try container.encode(ContextType.file, forKey: .type)
        case .image(let url):
            try container.encode(url, forKey: .url)
            try container.encode(ContextType.image, forKey: .type)
        case .tooBig(let url):
            try container.encode(url, forKey: .url)
            try container.encode(ContextType.tooBig, forKey: .type)
        case .error(let url, let error):
            try container.encode(url, forKey: .url)
            try container.encode(ContextType.error, forKey: .type)
            let errorDescription = (error as NSError).localizedDescription
            try container.encode(errorDescription, forKey: .error)
        case .webSearch(let title, let content, let source, let url):
            try container.encode(title, forKey: .title)
            try container.encode(content, forKey: .content)
            try container.encode(source, forKey: .source)
            if let url = url {
                try container.encode(url, forKey: .url)
            }
            try container.encode(ContextType.webSearch, forKey: .type)
        case .web(let websiteUrl, let websiteTitle, let webFileUrl):
            try container.encode(websiteUrl, forKey: .websiteUrl)
            try container.encode(websiteTitle, forKey: .websiteTitle)
            try container.encode(ContextType.web, forKey: .type)
            if let webFileUrl = webFileUrl {
                try container.encode(webFileUrl, forKey: .url)
            }
        }
    }
}

extension Context: Equatable, Hashable {
    static func == (lhs: Context, rhs: Context) -> Bool {
        switch (lhs, rhs) {
        case (.file(let url1), .file(let url2)),
            (.image(let url1), .image(let url2)),
            (.tooBig(let url1), .tooBig(let url2)):
            return url1 == url2
        case (.error(let url1, _), .error(let url2, _)):
            return url1 == url2
        case (.auto(let autoContext1), .auto(let autoContext2)):
            return autoContext1.appName == autoContext2.appName &&
            autoContext1.appHash == autoContext2.appHash &&
            autoContext1.appTitle == autoContext2.appTitle &&
            autoContext1.appContent == autoContext2.appContent
        case (.webSearch(let title1, let content1, let source1, _), .webSearch(let title2, let content2, let source2, _)):
            return title1 == title2 && content1 == content2 && source1 == source2
        case (.web(let websiteUrl1, _, _), .web(let websiteUrl2, _, _)):
            return websiteUrl1 == websiteUrl2
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .file(let url), .image(let url), .tooBig(let url), .error(let url, _), .web(let url, _, _):
            hasher.combine(url)
        case .auto(let autoContext):
            hasher.combine(autoContext)
        case .webSearch(let title, let content, let source, _):
            hasher.combine(title)
            hasher.combine(content)
            hasher.combine(source)
        }
    }
}

extension URL {
    var size: Int {
        get throws {
            let resourceValues = try resourceValues(forKeys: [.fileSizeKey])
            guard let size = resourceValues.fileSize else {
                throw ContextError.fileSizeNotFound
            }
            return size
        }
    }

    var isImage: Bool {
        let imageExtensions = ImageExtensions.allCases.map(\.rawValue)
        return imageExtensions.contains(self.pathExtension.lowercased())
    }
}

enum ContextError: Error {
    case fileSizeNotFound
}

extension [Context] {
    var files: [URL] {
        compactMap {
            switch $0 {
            case .file(let url):
                return url
            case .web(_, _, let webFileUrl):
                return webFileUrl
            default:
                return nil
            }
        }
    }

    var images: [URL] {
        compactMap {
            switch $0 {
            case .image(let url):
                return url
            default:
                return nil
            }
        }
    }
    
    var webSearchContexts: [(title: String, content: String, source: String, url: URL?)] {
        compactMap {
            switch $0 {
            case .webSearch(let title, let content, let source, let url):
                return (title, content, source, url)
            default:
                return nil
            }
        }
    }

    var autoContexts: [String: String] {
        var result: [String: String] = [:]
        
        for context in self {
            if case .auto(let autoContext) = context {
                let contentString = autoContext.appContent.values.joined(separator: "\n")
                if let existing = result[autoContext.appName] {
                    let combined = existing + "\n" + contentString
                    
                    result[autoContext.appName] = combined
                } else {
                    result[autoContext.appName] = contentString
                }
            }
        }
        
        return result
    }
}
