//
//  URL+MimeType.swift
//  Onit
//
//  Created by Kévin Naudin on 04/02/2025.
//

import Foundation
import UniformTypeIdentifiers

extension URL {
    
    var mimeType: String {
        let pathExtension = self.pathExtension
        if let uti = UTType(filenameExtension: pathExtension),
           let mimeType = uti.preferredMIMEType {
            return mimeType
        }
        return "application/octet-stream" // Fallback if MIME type is not found
    }
}
