//
//  HintManager.swift
//  Onit
//
//  Created by Loyd Kim on 1/22/26.
//

/*
 * Singleton
 * Initialization
 * Configuration
 * Variables: Hint Window
 * Variables: More Menu Window
 * Variables: Panels
 * Variables: Hover
 * Variables: Positioning
 * Variables: Detections
 * Variables: Subscriptions
 */

import Combine
import Defaults
import Foundation
import SwiftUI

enum HintMode {
    case tethered
    case pinned
    case untethered
}

enum HintPopUpMessageType: Equatable {
    case accessibilityLost
    /// Commented out for now until non-AX becomes the default state.
//        case screenRecordingLost
    case updateAvailable
    case hover

    var autoDismissDuration: Duration? {
        return nil
    }
}

@MainActor
final class HintManager: ObservableObject {
    // MARK: - Singleton

    static let shared = HintManager()
    
    // MARK: - Initialization

    private init() {
        class CustomPanel: NSPanel {
            override var canBecomeKey: Bool { false }
            override var canBecomeMain: Bool { false }
        }

        let window = CustomPanel(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.hidesOnDeactivate = false
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true

        self.hintWindow = window
    }

    // MARK: - Configuration

    func configure() {
        setupSubscriptions()
        startUpdateCheckSchedule()
    }

    /// Checks for an available update immediately on launch, then rechecks every 24 hours to catch updates released during long-running sessions.
    private func startUpdateCheckSchedule() {
        AppState.shared.checkForAvailableUpdate()

        let twentyFourHours: TimeInterval = 24 * 60 * 60
        
        updateCheckTimer = Timer.scheduledTimer(
            withTimeInterval: twentyFourHours,
            repeats: true
        ) { _ in
            Task { @MainActor in
                AppState.shared.checkForAvailableUpdate()
            }
        }
    }
    
    // MARK: - Variables: Update Check

    private var updateCheckTimer: Timer? {
        willSet {
            updateCheckTimer?.invalidate()
        }
    }

    // MARK: - Variables: Hint Window
    
    private(set) var hintWindow: NSWindow
    
    var currentHintSize: CGSize = .zero
    
    var hintWindowIsVisible: Bool {
        return
            hintWindow.contentView != nil &&
            hintWindow.isVisible
    }
    
    // MARK: - Variables: More Menu Window
    
    var moreMenuWindow: NSWindow?
    
    var moreMenuWindowIsVisible: Bool {
        guard let moreMenuWindow = self.moreMenuWindow
        else {
            return false
        }
        
        return
            moreMenuWindow.contentView != nil &&
            moreMenuWindow.isVisible
    }
    
    @Published var activePopUpType: HintPopUpMessageType? = nil

    var popUpAutoDismissTask: Task<Void, Never>? = nil

    var shouldShowAccessibilityLostPopUpMessage: Bool {
        return
            Defaults[.showHintAccessibilityAlert] &&
            !OnboardingWindowManager.shared.onboardingWindowIsVisible &&
            AccessibilityPermissionManager.shared.accessibilityPermissionStatus == .denied
    }

    /// Commented out for now until non-AX becomes the default state.
//    var shouldShowScreenRecordingLostPopUpMessage: Bool {
//        return
//            Defaults[.showHintScreenRecordingAlert] &&
//            !OnboardingWindowManager.shared.onboardingWindowIsVisible &&
//            !ScreenRecordingPermissionManager.shared.isScreenRecordingEnabled
//    }

    var shouldShowUpdateAvailablePopUpMessage: Bool {
        guard let availableVersion = AppState.shared.availableUpdateVersion else { return false }
        return
            Defaults[.showHintUpdateAvailableAlert] &&
            Defaults[.dismissedUpdateAlertVersion] != availableVersion &&
            AppState.shared.isUpdateAvailable
    }

    // MARK: - Variables: Panels

    var currentPanelState: OnitPanelState? = nil
    
    /// Timer for debouncing show operations.
    var showDebounceTimer: Timer? {
        willSet {
            showDebounceTimer?.invalidate()
        }
    }
    
    /// Debounce delay for showing the hint.
    let showDebounceDelay: TimeInterval = 0.1
    
    // MARK: - Variables: Hover
    
    /// Handling hint hovering on the AppKit window level, rather than the SwiftUI view level, to prevent layout change timing mismatches which cause flickering and multi-monitor bleeding.
    @Published var isHintHovered: Bool = false

    var localMouseEventMonitorForHoverTracking: Any?
    var globalMouseEventMonitorForHoverTracking: Any?

    /// Timer to debounce hover exit to prevent flicker during layout transitions.
    var hoverExitDebounceTimer: Timer? {
        willSet {
            hoverExitDebounceTimer?.invalidate()
        }
    }

    /// Debounce delay for hover exit (prevents flicker during layout changes).
    let hoverExitDebounceDelay: TimeInterval = 0.1

    // MARK: - Variables: Positioning
    
    /// Y-position for hint window drag.
    var lastYComputed: CGFloat? = nil
    
    // MARK: - Variables: Detections
    
    /// Current screen the hint is displayed on. Used to maintain proper monitor reference when repositioning. Helps with multi-monitor setups.
    var currentScreen: NSScreen? = nil
    
    /// Guard flag to prevent infinite constraint update loops when underlying hint SwiftUI view's size updates.
    var isHandlingFrameChange = false
    
    // MARK: - Variables: Subscriptions
    
    var cancellables = Set<AnyCancellable>()
}
