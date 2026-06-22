//
//  FeatureDisableManager+Scheduling.swift
//  Onit
//
//  Created by Kévin Naudin on 27/01/2026.
//

import AppKit
import Defaults

extension FeatureDisableManager {
    // MARK: - Timer Management

    func scheduleDisableRulesObserverTimer() {
        self.disableRulesObserverTimer?.invalidate()
        self.disableRulesObserverTimer = nil

        let nextExpirationDate = self.getNextClosestExpirationDate()
        let nextIgnoredUntilDate = self.getNextClosestIgnoredUntilDate()
        let nextTimeRangeDate = self.getNextClosestTimeRangeDate()

        let nextObservedDate = [nextExpirationDate, nextIgnoredUntilDate, nextTimeRangeDate].compactMap { $0 }.min()

        guard let observedDate = nextObservedDate else { return }

        let remainingTimeUntilPastObservedDate = observedDate.timeIntervalSinceNow

        // Short-circuit when the next-closest observed date has already passed
        guard remainingTimeUntilPastObservedDate > 0 else {
            self.refreshDisableRulesStates()
            return
        }

        self.disableRulesObserverTimer = Timer.scheduledTimer(
            withTimeInterval: remainingTimeUntilPastObservedDate,
            repeats: false
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDisableRulesStates()
            }
        }

        guard let observerTimer = self.disableRulesObserverTimer else { return }

        // Registering to the run loop allows the app to properly manage the expiration timer
        RunLoop.main.add(observerTimer, forMode: .common)
    }

    private func clearDisableRulesObservers() {
        self.disableRulesObserverTimer?.invalidate()
        self.disableRulesObserverTimer = nil

        self.systemLevelObservers.forEach { NotificationCenter.default.removeObserver($0) }
        self.systemLevelObservers.removeAll()
    }

    // MARK: - Initialization

    func initializeDisableObservers() {
        self.systemLevelObservers = [
            NotificationCenter.default.addObserver(
                forName: .NSSystemClockDidChange,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshDisableRulesStates()
                }
            },

            NotificationCenter.default.addObserver(
                forName: .NSCalendarDayChanged,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshDisableRulesStates()
                }
            },

            NotificationCenter.default.addObserver(
                forName: NSWorkspace.didWakeNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.refreshDisableRulesStates()
                }
            },

            NotificationCenter.default.addObserver(
                forName: NSApplication.willTerminateNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task { @MainActor in
                    self?.clearDisableRulesObservers()
                }
            }
        ]

        self.refreshDisableRulesStates()
    }

    // MARK: - Refresh States

    func refreshDisableRulesStates() {
        self.removeExpiredDisableRules()
        self.removeExpiredIgnoredDisableRules()
        self.scheduleDisableRulesObserverTimer()
    }
}
