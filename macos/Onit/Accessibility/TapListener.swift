//
//  TapListener.swift
//  Onit
//
//  Created by Kévin Naudin on 22/01/2025.
//


import Foundation
import SwiftUI

@MainActor
class TapListener {
    
    // MARK: - Singleton instance
    
    static let shared = TapListener()
    
    // MARK: - Properties
    
    private var tapObserver: CFMachPort?
    
    // MARK: - Initializers
    
    private init() { }
    
    // MARK: - Functions
    
    func start() {
        // Setup mouse click observer
        let eventMask = (1 << CGEventType.leftMouseUp.rawValue) |
        (1 << CGEventType.rightMouseUp.rawValue)
        
        if let eventTap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                DispatchQueue.main.async {
                    switch type {
                    case .leftMouseDown, .rightMouseDown:
                        print("Mouse down detected!")
                    case .leftMouseUp, .rightMouseUp:
                        print("Mouse up detected!")
                        Task { @MainActor in
                            // self.handleMouseUp()
                        }
                    default:
                        break
                    }
                }
                return Unmanaged.passUnretained(event) // Ensure the event is returned
            },
            userInfo: nil
        ) {
            self.tapObserver = eventTap
            let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
            CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
            CGEvent.tapEnable(tap: eventTap, enable: true)
        } else {
            print("Failed to create event tap.")
        }
    }
    
    func stop() {
        guard let tapObserver = self.tapObserver else {
            print("No active tap observer to stop.")
            return
        }
        
        CGEvent.tapEnable(tap: tapObserver, enable: false)
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tapObserver, 0)
        CFRunLoopRemoveSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        
        CFMachPortInvalidate(tapObserver)
        self.tapObserver = nil
    }
    
    //    private func handleMouseUp() {
    //        if appElement != nil {
    //            print("Mouse up!")
    //        }
    //        else {
    //            print("No app ELement, skipping")
    //        }
    //    }
    
}
