//
//  Image+JPEG.swift
//  Onit
//
//  Created by Benjamin Sage on 10/29/24.
//

import AppKit
import Foundation

extension NSImage {
    var jpeg: Data? {
        jpegData(compressionQuality: 0.8)
    }

    func jpegData(compressionQuality: CGFloat) -> Data? {
        guard let tiffData = self.tiffRepresentation,
            let bitmapImage = NSBitmapImageRep(data: tiffData)
        else {
            return nil
        }
        return bitmapImage.representation(
            using: .jpeg, properties: [.compressionFactor: compressionQuality])
    }
}
