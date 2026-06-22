//
//  AppAppearance.swift
//  Onit
//
//  Created by Loyd Kim on 11/26/25.
//

import AppKit
import Defaults
import SwiftUI

enum AppAppearance: String, CaseIterable, Identifiable, Defaults.Serializable {
    case system
    case light
    case dark

    var id: String { rawValue }

    @MainActor
    var displayName: String {
        switch self {
        case .system:
            return String.localized("Auto", table: "Settings")
        case .light:
            return String.localized("Light", table: "Settings")
        case .dark:
            return String.localized("Dark", table: "Settings")
        }
    }
    
    static var current: Self {
        Defaults[.appAppearance]
    }

    @MainActor
    static func set(_ appearance: Self) {
        Defaults[.appAppearance] = appearance
        Self.apply(appearance)
    }

    @MainActor
    static func applyCurrent() {
        Self.apply(Self.current)
    }
    
    @MainActor
    static func apply(_ appearance: Self) {
        switch appearance {
        case .system:
            NSApp.appearance = nil
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }
}
