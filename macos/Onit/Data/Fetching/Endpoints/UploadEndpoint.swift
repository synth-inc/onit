//
//  ChatEndpoint.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation
import AppKit
import UniformTypeIdentifiers

enum UploadProgress {
    case progress(Double)
    case completed(URL)
}

extension FetchingClient {
    func upload(image: URL) -> AsyncStream<UploadProgress> {
        AsyncStream { continuation in
            let fileExtension = image.pathExtension.lowercased()
            let name = "\(UUID()).\(fileExtension)"
            let urlString = "\(String.azureBase)/\(String.azureBucket)/\(name)?\(String.sasKey)"
            let mimeType = mimeTypeForPath(path: image.absoluteString)

            let validExtensions = ImageExtensions.allCases.map(\.rawValue)
            guard validExtensions.contains(fileExtension) else {
                return
//                throw UploadError.invalidFileFormat
            }

            guard let url = URL(string: urlString) else {
                return
//                throw UploadError.urlParsing
            }
            let additionalHeaders = [
                "x-ms-blob-type": "BlockBlob",
                "x-ms-version": "2023-11-03",
                "x-ms-date": date
            ]

            let request = makeRequest(
                from: url, method: .put, body: .url(image), contentType: mimeType, additionalHeaders: additionalHeaders
            )

            let progressDelegate = ProgressDelegate(continuation: continuation)
            let session = URLSession(configuration: .default, delegate: progressDelegate, delegateQueue: nil)

            Task {
                do {
                    let _ = try await session.upload(for: request, fromFile: image)
                    continuation.yield(.completed(url.stripped))
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }

    private final class ProgressDelegate: NSObject, URLSessionTaskDelegate {
        private let continuation: AsyncStream<UploadProgress>.Continuation

        init(continuation: AsyncStream<UploadProgress>.Continuation) {
            self.continuation = continuation
        }

        func urlSession(
            _ session: URLSession,
            task: URLSessionTask,
            didSendBodyData bytesSent: Int64,
            totalBytesSent: Int64,
            totalBytesExpectedToSend: Int64
        ) {
            let progress = Double(totalBytesSent) / Double(totalBytesExpectedToSend)
            continuation.yield(.progress(progress))
        }
    }

    private func mimeTypeForPath(path: String) -> String {
        let url = URL(fileURLWithPath: path)
        let pathExtension = url.pathExtension
        let utType = UTType(filenameExtension: pathExtension)
        if let mimeType = utType?.preferredMIMEType {
            return mimeType
        } else {
            return "application/octet-stream"
        }
    }

    private var date: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        let date = Date()
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
}

enum UploadError: Error {
    case invalidFileFormat
    case urlParsing
}

// MARK: - Keys

extension String {
    fileprivate static let azureBase = "https://onit.blob.core.windows.net"
    fileprivate static let azureBucket = "onit"
    fileprivate static let sasKey = """
sv=2022-11-02&ss=bfqt&srt=o&sp=rwdlacupiytfx&se=2025-10-29T15:06:42Z&st=2024-10-29T07:06:42Z&spr=https&sig=kleAK3lON2b6\
kIk6UCQ%2FXOXH15k8HFjjMUwPWxMpptk%3D
"""
}