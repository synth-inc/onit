//
//  OptionSet+ActiveModifiers.swift
//  Omni
//
//  Created by Benjamin Sage on 9/20/24.
//

import SwiftUI

extension EventModifiers {
    static let allModifiers: [EventModifiers] = [
        .capsLock,
        .control,
        .option,
        .shift,
        .command,
        .numericPad
    ]

    var array: [EventModifiers] {
        EventModifiers.allModifiers.filter { self.contains($0) }
    }
}

extension EventModifiers: @retroactive Identifiable {
    public var id: EventModifiers.RawValue { self.rawValue }
}
