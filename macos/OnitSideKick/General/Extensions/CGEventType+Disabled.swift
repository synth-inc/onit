//
//  CGEventType+Disabled.swift
//  Onit
//
//  Created by Kévin Naudin on 21/11/2025.
//

import AppKit

extension CGEventType {
    
    func reenableIfDisabled(event: CGEvent, eventTap: CFMachPort?) -> Unmanaged<CGEvent>? {
        if self == .tapDisabledByTimeout || self == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        return nil
    }
}
