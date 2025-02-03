//
//  FetchingClient.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Defaults
import Foundation
import UniformTypeIdentifiers

actor FetchingClient {
    let session = URLSession.shared
    let encoder = JSONEncoder()
    let decoder = {
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        return decoder
    }()
    
    func mimeType(for url: URL) -> String {
        let pathExtension = url.pathExtension
        if let uti = UTType(filenameExtension: pathExtension),
            let mimeType = uti.preferredMIMEType
        {
            return mimeType
        }
        return "application/octet-stream"  // Fallback if MIME type is not found
    }
}
