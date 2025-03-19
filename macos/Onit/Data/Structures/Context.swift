//
//  Context.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import Foundation
import AppKit

enum Context {
    case auto(String, [String: String])
    case file(URL)
    case image(URL)
    case tooBig(URL)
    case error(URL, Error)
    case loading(String)
    case webAuto(String, [String: String], WebMetadata)

    static let maxFileSize: Int = 1024 * 1024 * 1
    static let maxImageSize: Int = 1024 * 1024 * 20

    var url: URL? {
        switch self {
        case .auto:
            return nil
        case .file(let url), .image(let url), .tooBig(let url), .error(let url, _):
            return url
        case .loading:
            return nil
        case .webAuto:
            return nil
        }
    }

    var fileType: String? {
        switch self {
        case .auto(let appName, _):
            if appName.starts(with: "Web:") {
                return "Web"
            }
            return "Auto"
        case .file:
            return "File"
        case .image:
            return "Img"
        case .loading:
            return "Web"
        case .webAuto(let appName, _, _):
            if appName.starts(with: "Web:") {
                return "Web"
            }
            return "Auto"
        default:
            return nil
        }
    }

    var isAutoContext: Bool {
        switch self {
        case .auto, .webAuto:
            return true
        default:
            return false
        }
    }
}

extension Context {
    init(appName: String, appContent: [String: String]) {
        self = .auto(appName, appContent)
    }

    init(url: URL) {
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
}

extension Context: Codable {
    enum CodingKeys: String, CodingKey {
        case appName, appContent, type, url, error, faviconImage, title
    }

    enum ContextType: String, Codable {
        case auto, file, image, tooBig, error, loading, webAuto
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContextType.self, forKey: .type)

        switch type {
        case .auto:
            let appName = try container.decode(String.self, forKey: .appName)
            let appContent = try container.decode([String: String].self, forKey: .appContent)
            self = .auto(appName, appContent)
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
        case .loading:
            let loadingString = try container.decode(String.self, forKey: .appName)
            self = .loading(loadingString)
        case .webAuto:
            let appName = try container.decode(String.self, forKey: .appName)
            let appContent = try container.decode([String: String].self, forKey: .appContent)
            let faviconImageData = try container.decodeIfPresent(Data.self, forKey: .faviconImage)
            let title = try container.decodeIfPresent(String.self, forKey: .title)
            let metadata = WebMetadata(title: title, faviconImageData: faviconImageData)
            self = .webAuto(appName, appContent, metadata)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        switch self {
        case .auto(let appName, let appContent):
            try container.encode(appName, forKey: .appName)
            try container.encode(appContent, forKey: .appContent)
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
        case .loading(let loadingString):
            try container.encode(loadingString, forKey: .appName)
            try container.encode(ContextType.loading, forKey: .type)
        case .webAuto(let appName, let appContent, let metadata):
            try container.encode(appName, forKey: .appName)
            try container.encode(appContent, forKey: .appContent)
            try container.encode(metadata.title, forKey: .title)
            if let faviconImageData = metadata.faviconImageData {
                try container.encode(faviconImageData, forKey: .faviconImage)
            }
            try container.encode(ContextType.webAuto, forKey: .type)
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
        case (.auto(let appName1, let content1), .auto(let appName2, let content2)):
            return appName1 == appName2 && content1 == content2
        case (.loading(let loadingString1), .loading(let loadingString2)):
            return loadingString1 == loadingString2
        case (.webAuto(let appName1, let content1, let metadata1), .webAuto(let appName2, let content2, let metadata2)):
            return appName1 == appName2 && content1 == content2 && metadata1 == metadata2
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case .file(let url), .image(let url), .tooBig(let url), .error(let url, _):
            hasher.combine(url)
        case .auto(let appName, let appContent):
            hasher.combine(appName)
            hasher.combine(appContent)
        case .loading(let loadingString):
            hasher.combine(loadingString)
        case .webAuto(let appName, let appContent, let metadata):
            hasher.combine(appName)
            hasher.combine(appContent)
            hasher.combine(metadata)
        }
    }
}

struct WebMetadata: Hashable, Sendable {
    let title: String?
    let faviconImageData: Data?
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(title)
        hasher.combine(faviconImageData)
    }
    
    static func == (lhs: WebMetadata, rhs: WebMetadata) -> Bool {
        lhs.title == rhs.title && lhs.faviconImageData == rhs.faviconImageData
    }
    
    var faviconImage: NSImage? {
        if let data = faviconImageData {
            return NSImage(data: data)
        }
        return nil
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

    var autoContexts: [String: String] {
        var result: [String: String] = [:]
        
        for context in self {
            if case .auto(let appName, let content) = context {
                let contentString = content.values.joined(separator: "\n")
                if let existing = result[appName] {
                    let combined = existing + "\n" + contentString
                    
                    result[appName] = combined
                } else {
                    result[appName] = contentString
                }
            } else if case .webAuto(let appName, let content, _) = context {
                let contentString = content.values.joined(separator: "\n")
                if let existing = result[appName] {
                    let combined = existing + "\n" + contentString
                    
                    result[appName] = combined
                } else {
                    result[appName] = contentString
                }
            }
        }
        
        return result
    }
}
