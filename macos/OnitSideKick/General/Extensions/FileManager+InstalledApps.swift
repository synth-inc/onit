//
//  FileManager+InstalledApps.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import AppKit

extension FileManager {
    
    func installedApps() -> [URL] {
        var apps: Set<URL> = []
        
        // Search directories for applications
        let searchPaths: [URL] = [
            // /Applications (user-installed apps)
            URL(fileURLWithPath: "/Applications"),
            // /System/Applications (system apps like Notes, Safari, etc.)
            URL(fileURLWithPath: "/System/Applications"),
            // ~/Applications (user's personal apps)
            self.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        for searchPath in searchPaths {
            guard self.fileExists(atPath: searchPath.path) else { continue }

            if let enumerator = self.enumerator(
                at: searchPath,
                includingPropertiesForKeys: [.isApplicationKey],
                options: [.skipsHiddenFiles]
            ) {
                while let element = enumerator.nextObject() as? URL {
                    if element.pathExtension == "app" {
                        apps.insert(element)
                        // Don't descend into .app bundles
                        enumerator.skipDescendants()
                    }
                }
            }
        }

        return Array(apps)
    }
}

