//
//  Context.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import Foundation

enum Context {
    case file(URL)
    case image(URL)
    case tooBig(URL)
    case error(URL, Error)

    static let maxFileSize: Int = 1024 * 1024 * 1
    static let maxImageSize: Int = 1024 * 1024 * 20

    var url: URL {
        switch self {
        case .file(let url), .image(let url), .tooBig(let url), .error(let url, _):
            return url
        }
    }

    var fileType: String? {
        switch self {
        case .file:
            "file"
        case .image:
            "Img"
        default:
            nil
        }
    }
}

extension Context {
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
        case type, url, error
    }

    enum ContextType: String, Codable {
        case file, image, tooBig, error
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(ContextType.self, forKey: .type)
        let url = try container.decode(URL.self, forKey: .url)
        
        switch type {
        case .file:
            self = .file(url)
        case .image:
            self = .image(url)
        case .tooBig:
            self = .tooBig(url)
        case .error:
            let errorDescription = try container.decode(String.self, forKey: .error)
            let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: errorDescription])
            self = .error(url, error)
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(url, forKey: .url)
        
        switch self {
        case .file:
            try container.encode(ContextType.file, forKey: .type)
        case .image:
            try container.encode(ContextType.image, forKey: .type)
        case .tooBig:
            try container.encode(ContextType.tooBig, forKey: .type)
        case .error(_, let error):
            try container.encode(ContextType.error, forKey: .type)
            let errorDescription = (error as NSError).localizedDescription
            try container.encode(errorDescription, forKey: .error)
        }
    }
}

extension Context: Equatable, Hashable {
    static func == (lhs: Context, rhs: Context) -> Bool {
        lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
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
