//
//  MacHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 9/3/25.
//

import Foundation

struct MacHelpers {
    static func getRemainingStorageInBytes(directoryUrl: URL? = nil) -> Int {
        do {
            let targetDirectoryUrl = directoryUrl ?? FileManager.default.homeDirectoryForCurrentUser
            
            let resourceValues = try targetDirectoryUrl.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeAvailableCapacityKey,
                .volumeAvailableCapacityForOpportunisticUsageKey
            ])
            
            if let importantUsage = resourceValues.volumeAvailableCapacityForImportantUsage {
                return Int(importantUsage)
            } else if let availableCapacity = resourceValues.volumeAvailableCapacity {
                return Int(availableCapacity)
            } else if let opportunisticUsage = resourceValues.volumeAvailableCapacityForOpportunisticUsage {
                return Int(opportunisticUsage)
            }
        } catch {
            print("Error getting remaining storage: \(error.localizedDescription)")
        }
        
        return 0
    }
}
