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
            if try url.size > Self.maxFileSize {
                self = .tooBig(url)
            } else if url.isImage {
                self = .image(url)
            } else {
                self = .file(url)
            }
        } catch {
            self = .error(url, error)
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
        let imageExtensions = ["png", "jpg", "jpeg", "gif", "tiff", "bmp"]
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
            case .image(let url), .file(let url):
                return url
            default:
                return nil
            }
        }
    }
}
