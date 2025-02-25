//
//  FileManager+InstalledApps.swift
//  Onit
//
//  Created by Kévin Naudin on 07/02/2025.
//

import AppKit

extension FileManager {
    
    func installedApps() -> [URL] {
        var apps: [URL] = []

        if let appsURL = self.urls(for: .applicationDirectory, in: .localDomainMask).first {
            if let enumerator = self.enumerator(at: appsURL, includingPropertiesForKeys: nil, options: .skipsSubdirectoryDescendants) {
                while let element = enumerator.nextObject() as? URL {
                    if element.pathExtension == "app" {
                        apps.append(element)
                    }
                }
            }
        }

        return apps
    }
}

