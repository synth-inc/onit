//
//  SpaceMonitoringManager.swift
//  Onit
//
//  Created by Kévin Naudin on 20/05/2025.
//


import Foundation
import AppKit

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ connection: Int) -> CFArray?

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> Int

/**
 * This class uses Private API to determine on which screen the active space changed
 */
class SpaceMonitoringManager {
    
    // MARK: - DisplaySpaceInfo
    
    typealias CGSSpaceID = UInt64
    
    struct DisplaySpaceInfo {
        let availableSpaces: [CGSSpaceID]
        let currentSpace: CGSSpaceID
    }
    
    // MARK: - Properties
    
    private var lastMapping: [String: DisplaySpaceInfo] = [:]
    private var callback: ((NSScreen) -> Void)?
    
    // MARK: - Functions
    
    func start(onSpaceChange: @escaping (NSScreen) -> Void) {
        self.callback = onSpaceChange
        self.lastMapping = Self.getDisplaySpaceMapping()
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceChanged),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
    }
    
    func stop() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        callback = nil
        lastMapping = [:]
    }
    
    @objc private func spaceChanged() {
        let newMapping = Self.getDisplaySpaceMapping()
        
        for (displayID, newInfo) in newMapping {
            let oldInfo = lastMapping[displayID]
            
            if oldInfo == nil || newInfo.currentSpace != oldInfo?.currentSpace {
                if let screen = Self.screen(forDisplayUUID: displayID) {
                    callback?(screen)
                }
            }
        }
        
        lastMapping = newMapping
    }
    
    private static func getDisplaySpaceMapping() -> [String: DisplaySpaceInfo] {
        var result: [String: DisplaySpaceInfo] = [:]
        let connection = CGSMainConnectionID()
        
        guard let displaySpaces = CGSCopyManagedDisplaySpaces(connection) as? [[String: Any]] else {
            return result
        }
        
        for displaySpace in displaySpaces {
            if let displayID = displaySpace["Display Identifier"] as? String,
               let spaces = displaySpace["Spaces"] as? [[String: Any]],
               let currentSpace = displaySpace["Current Space"] as? [String: Any],
               let currentSpaceID = currentSpace["ManagedSpaceID"] as? CGSSpaceID {
                
                let spaceIDs = spaces.compactMap { $0["ManagedSpaceID"] as? CGSSpaceID }
                result[displayID] = DisplaySpaceInfo(availableSpaces: spaceIDs, currentSpace: currentSpaceID)
            }
        }
        
        return result
    }
    
    private static func screen(forDisplayUUID uuid: String) -> NSScreen? {
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID,
               let cfUUID = CGDisplayCreateUUIDFromDisplayID(screenNumber)?.takeRetainedValue() {
                let screenUUID = CFUUIDCreateString(nil, cfUUID) as String
                
                if screenUUID.lowercased() == uuid.lowercased() {
                    return screen
                }
            }
        }
        
        return nil
    }
}
