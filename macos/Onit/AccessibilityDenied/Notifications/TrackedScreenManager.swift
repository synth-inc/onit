//
//  TrackedScreenManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 4/23/25.
//

import Foundation
import AppKit

struct TrackedScreen: Hashable {
    
    let frame: NSRect
    let screen: NSScreen
    let visibleFrame: NSRect
    let localizedName: String
    
    static func == (lhs: TrackedScreen, rhs: TrackedScreen) -> Bool {
        return NSEqualRects(lhs.frame, rhs.frame) && NSEqualRects(lhs.visibleFrame, rhs.visibleFrame) && lhs.localizedName == rhs.localizedName
    }
}

enum TrackedScreenAction {
    case undefined
    case activate
}

@MainActor
class TrackedScreenManager: ObservableObject {
    var activeTrackedScreen: TrackedScreen?
    static let shared = TrackedScreenManager()
    
    private var trackedScreens: [TrackedScreen] = []

    func append(screen: NSScreen) -> TrackedScreen? {
        let trackedScreen = TrackedScreen(frame: screen.frame, screen: screen, visibleFrame: screen.visibleFrame, localizedName: screen.localizedName)
        if !trackedScreens.contains(trackedScreen) {
            trackedScreens.append(trackedScreen)
        }   
        activeTrackedScreen = trackedScreen
        return activeTrackedScreen
    }

    func remove(screen: NSScreen) {
        trackedScreens.removeAll { $0.frame == screen.frame }
    }
}
