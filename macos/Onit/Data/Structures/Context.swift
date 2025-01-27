//
//  Context.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import Foundation

enum Context {
    case auto(String, [String: String])
    case file(URL)
    case image(URL)
    case tooBig(URL)
    case error(URL, Error)

    static let maxFileSize: Int = 1024 * 1024 * 1
    static let maxImageSize: Int = 1024 * 1024 * 20

    var url: URL? {
        switch self {
        case .auto:
            return nil
        case .file(let url), .image(let url), .tooBig(let url), .error(let url, _):
            return url
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
        case appName, appContent, type, url, error
    }

    enum ContextType: String, Codable {
        case auto, file, image, tooBig, error
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
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            self = .error(url, error)
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
            default:
                return nil
            }
        }
    }
    
    var images : [URL] {
        compactMap {
            switch $0 {
            case .image(let url):
                return url
            default:
                return nil
            }
        }
    }
}
