//
//  ImageUtilities.swift
//  Onit
//
//  Created by Assistant on [Current Date]
//

import AppKit
import Foundation

struct ImageUtilities {
    
    /// Saves an NSImage to disk as a PNG file in the temporary directory
    /// This operation runs on a background thread to avoid blocking the main UI thread
    /// - Parameters:
    ///   - image: The NSImage to save
    ///   - prefix: A prefix to add to the filename for identification
    /// - Returns: The file path if successful, nil if failed
    static func saveImageToDisk(_ image: NSImage?, prefix: String) async -> String? {
        // Extract image data on the main thread to avoid data races
        guard let image = image,
              let data = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: data),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        return await Task.detached(priority: .utility) {
            let tempPath = URL(fileURLWithPath: NSTemporaryDirectory())
            let imagesFolder = tempPath.appendingPathComponent("OnitImages")
            try? FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
            
            let fileName = "\(prefix)_\(Date().timeIntervalSince1970).png"
            let fileURL = imagesFolder.appendingPathComponent(fileName)

            do {
                try pngData.write(to: fileURL)
                return fileURL.path
            } catch {
                print("Failed to save image to disk: \(error)")
                return nil
            }
        }.value
    }
    
    /// Removes an image file from disk
    /// This operation runs on a background thread to avoid blocking the main UI thread
    /// - Parameter filePath: The path to the image file to remove
    /// - Returns: True if successful, false if failed
    static func removeImageFromDisk(at filePath: String) async -> Bool {
        let capturedPath = filePath
        return await Task.detached(priority: .utility) {
            do {
                try FileManager.default.removeItem(atPath: capturedPath)
                return true
            } catch {
                print("Failed to remove image from disk: \(error)")
                return false
            }
        }.value
    }
} 