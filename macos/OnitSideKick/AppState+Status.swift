//
//  AppState+Status.swift
//  Onit
//
//  Created by Kévin Naudin on 28/11/2025.
//

import AppKit
import Combine
import Defaults
import Foundation

// MARK: - App Status Types

/// Status dot color in the menu bar
enum AppStatusDotColor {
    case red      // Critical error (accessibility missing)
    case orange   // Warning (app disabled)
    case gray     // All features disabled
    case green    // All good

    /// Converts to NSColor for the UI
    var nsColor: NSColor {
        switch self {
        case .red:
            return NSColor.red500
        case .orange:
            return NSColor.orange500
        case .gray:
            return NSColor.gray200
        case .green:
            return NSColor.lime400
        }
    }
}

/// Main app status (first line of the menu)
enum AppStatusMessage: Equatable {
    // Dev build coexistence (priority -1, highest)
    case devBuildRunning

    // Global status (priority 0)
    case accessibilityRequired

    // Feature disable statuses (priority 4)
    case disabledInPrivateBrowsing
    case disabledGloballyIndefinitely
    case disabledGloballyTemporarily(expirationDate: Date)
    case disabledGloballyTimeRange(startTime: Date, endTime: Date)
    case disabledForAppIndefinitely(appName: String)
    case disabledForAppTemporarily(appName: String, expirationDate: Date)
    case disabledForAppTimeRange(appName: String, startTime: Date, endTime: Date)

    // All features disabled (priority 5)
    case allFeaturesDisabled

    case running

    /// Text to display in the menu
    @MainActor
    var displayText: String {
        switch self {
        case .devBuildRunning:
            return String.localized("A dev version is running")
        case .accessibilityRequired:
            return String.localized("Grant Accessibility →")

        case .disabledInPrivateBrowsing:
            return String.localized("Disabled in Private Browsing")
        case .disabledGloballyIndefinitely:
            return String.localized("Disabled Everywhere")
        case .disabledGloballyTemporarily(let expirationDate):
            let expirationDateText = DateHelpers.formatDateToTimeRemaining(expirationDate)
            return String.localized("Disabled Everywhere: %@", expirationDateText)
        case .disabledGloballyTimeRange(let startTime, let endTime):
            let startTimeText = DateHelpers.formatDateToTimeOfDay(startTime)
            let endTimeText = DateHelpers.formatDateToTimeOfDay(endTime)
            return String.localized("Disabled Everywhere: %@ - %@", startTimeText, endTimeText)
        case .disabledForAppIndefinitely(let appName):
            return String.localized("Disabled in %@", appName)
        case .disabledForAppTemporarily(let appName, let expirationDate):
            let expirationDateText = DateHelpers.formatDateToTimeRemaining(expirationDate)
            return String.localized("Disabled in %@: %@", appName, expirationDateText)
        case .disabledForAppTimeRange(let appName, let startTime, let endTime):
            let startTimeText = DateHelpers.formatDateToTimeOfDay(startTime)
            let endTimeText = DateHelpers.formatDateToTimeOfDay(endTime)
            return String.localized("Disabled in %@: %@ - %@", appName, startTimeText, endTimeText)

        case .allFeaturesDisabled:
            return String.localized("All features disabled")

        case .running:
            return String.localized("Running")
        }
    }

    /// Is the item clickable?
    var isActionable: Bool {
        switch self {
        case .accessibilityRequired,
             .allFeaturesDisabled:
            return true
        default:
            return false
        }
    }

    /// Requires a countdown for remaining seconds
    var requiresCountdown: Bool {
        switch self {
        case .disabledGloballyTemporarily(let expirationDate),
             .disabledForAppTemporarily(_, let expirationDate):
            let secondsUntilExpiration = Int(DateHelpers.getRemainingTimeInSeconds(endDate: expirationDate))
            return secondsUntilExpiration >= 0 && secondsUntilExpiration < 60
        default:
            return false
        }
    }
}

// MARK: - App Status Extension

extension AppState {

    // MARK: - Status Setup

    /// Initializes observers for app status
    /// Must be called after AppState initialization
    func setupStatusObservers() {
        // Initial update
        updateStatus()

        // Accessibility
        AccessibilityPermissionManager.shared.$accessibilityPermissionStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatus() }
            .store(in: &statusObserverCancellables)

        // Feature disable rules
        Defaults.publisher(.featureDisableRules)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatus() }
            .store(in: &statusObserverCancellables)

        // Mode toggles
        Defaults.publisher(.enableSidebar)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatus() }
            .store(in: &statusObserverCancellables)

        // Dev build detection (Release builds only)
        #if !DEBUG
        DevBuildDetectionService.shared.$isDevBuildRunning
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.updateStatus() }
            .store(in: &statusObserverCancellables)
        #endif

        // Setup badge count observers (for properties not already observed above)
        setupBadgeCountObservers()
    }

    // MARK: - Status Update

    /// Notification sent when status changes
    static let statusDidChangeNotification = Notification.Name("AppStateStatusDidChange")

    private func updateStatus() {
        let newMessage = computeStatusMessage()
        let newDotColor = computeStatusDotColor(for: newMessage)

        let didChange = statusDotColor != newDotColor || statusMessage != newMessage

        statusDotColor = newDotColor
        statusMessage = newMessage

        if didChange {
            NotificationCenter.default.post(name: Self.statusDidChangeNotification, object: nil)
        }

        // Also update badge count since many of the same conditions affect it
        updateSetupBadgeCount()
    }

    /// Derives dot color from status message to ensure consistency
    private func computeStatusDotColor(for message: AppStatusMessage) -> AppStatusDotColor {
        switch message {
        // GRAY: Dev build is running (production defers)
        case .devBuildRunning:
            return .gray

        // RED: Critical errors
        case .accessibilityRequired:
            return .red

        // ORANGE: Warnings
        case .disabledInPrivateBrowsing,
             .disabledGloballyIndefinitely,
             .disabledGloballyTemporarily,
             .disabledGloballyTimeRange,
             .disabledForAppIndefinitely,
             .disabledForAppTemporarily,
             .disabledForAppTimeRange:
            return .orange

        // GRAY: All features disabled
        case .allFeaturesDisabled:
            return .gray

        // GREEN: All good
        case .running:
            return .green
        }
    }

    private var allFeaturesDisabled: Bool {
        return !AppModeCoordinator.shared.isPanelEnabled
    }

    private func computeStatusMessage() -> AppStatusMessage {
        let accessibilityManager = AccessibilityPermissionManager.shared

        // PRIORITY -1: Dev build is running (Release/non-beta builds only)
        #if !DEBUG && !ONIT_BETA
        if DevBuildDetectionService.shared.isDevBuildRunning {
            return .devBuildRunning
        }
        #endif

        // PRIORITY 0: Accessibility not granted
        if accessibilityManager.accessibilityPermissionStatus != .granted {
            return .accessibilityRequired
        }

        // PRIORITY 4: FeatureDisableStatus (for menuDefault features)
        let disableStatus = FeatureDisableManager.shared.currentDisableStatus(for: .menuDefault)
        switch disableStatus {
        case .disabledInPrivateBrowsing:
            return .disabledInPrivateBrowsing
        case .disabledGloballyIndefinitely:
            return .disabledGloballyIndefinitely
        case .disabledGloballyTemporarily(let expirationDate):
            return .disabledGloballyTemporarily(expirationDate: expirationDate)
        case .disabledGloballyTimeRange(let startTime, let endTime):
            return .disabledGloballyTimeRange(startTime: startTime, endTime: endTime)
        case .disabledForAppIndefinitely(let app):
            return .disabledForAppIndefinitely(appName: app.name)
        case .disabledForAppTemporarily(let app, let expirationDate):
            return .disabledForAppTemporarily(appName: app.name, expirationDate: expirationDate)
        case .disabledForAppTimeRange(let app, let startTime, let endTime):
            return .disabledForAppTimeRange(appName: app.name, startTime: startTime, endTime: endTime)
        case .notDisabled:
            break
        }

        // PRIORITY 5: All features disabled
        if allFeaturesDisabled {
            return .allFeaturesDisabled
        }

        return .running
    }

    /// Action to execute when user clicks on the status
    func handleStatusAction() {
        switch statusMessage {
        case .accessibilityRequired:
            AccessibilityPermissionManager.shared.requestPermission()
        case .allFeaturesDisabled:
            SettingsWindowManager.shared.showWindow(page: .panelBehavior)
        default:
            break
        }
    }

    // MARK: - Badge Count

    private func setupBadgeCountObservers() {
        // Initial update
        updateSetupBadgeCount()

        // Note: Accessibility, mode toggles, and onboarding step
        // are already observed by setupStatusObservers() - they call updateStatus()
        // which now also updates the badge count
    }

    private func updateSetupBadgeCount() {
        let accessibilityManager = AccessibilityPermissionManager.shared

        var count = 0

        // System permissions (always required)
        if accessibilityManager.accessibilityPermissionStatus != .granted {
            count += 1
        }

        setupBadgeCount = count == 0 ? nil : count
    }
}
