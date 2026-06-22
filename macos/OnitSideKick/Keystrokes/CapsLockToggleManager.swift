//
//  CapsLockToggleManager.swift
//  Onit
//
//  Created by Codex on 2/5/26.
//

import AppKit
import IOKit
import IOKit.hidsystem

enum CapsLockToggleManager {
    static var isEnabled: Bool {
        CGEventSource.flagsState(.combinedSessionState).contains(.maskAlphaShift)
    }

    static func toggle() {
        setEnabled(!isEnabled)
    }

    static func setEnabled(_ enabled: Bool) {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching(kIOHIDSystemClass))
        guard service != 0 else {
            log.error("CapsLock toggle: Unable to find IOHIDSystem service.")
            return
        }

        var connect: io_connect_t = 0
        let openResult = IOServiceOpen(service, mach_task_self_, UInt32(kIOHIDParamConnectType), &connect)
        IOObjectRelease(service)

        guard openResult == KERN_SUCCESS else {
            log.error("CapsLock toggle: IOServiceOpen failed (\(openResult)).")
            return
        }

        defer { IOServiceClose(connect) }

        let result = IOHIDSetModifierLockState(connect, Int32(kIOHIDCapsLockState), enabled)
        if result != KERN_SUCCESS {
            log.error("CapsLock toggle: IOHIDSetModifierLockState failed (\(result)).")
        }
    }
}
