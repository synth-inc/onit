//
//  MenuBarHideTimerStatus.swift
//  Onit
//
//  Created by Loyd Kim on 9/25/25.
//

import AppKit
import Combine
import Defaults

final class MenuBarHideTimerStatus: MenuBarItemBase {
    // MARK: - Properties

    var isHideAllAppsTimerActive: Bool = false

    // MARK: - Initializer

    convenience init(isHideAllAppsTimerActive: Bool) {
        self.init(title: "", action: (nil as Selector?), keyEquivalent: "")
        self.isHideAllAppsTimerActive = isHideAllAppsTimerActive
    }

    override func initializeProperties() {
        self.title = ""
        self.image = self.statusDot
        self.action = #selector(cancelHideTimer)
        self.keyEquivalent = ""
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.setMenuItemTitle()

        Defaults.publisher(.tetheredButtonHideAllAppsTimerDate)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.tetheredButtonHideAllAppsTimerDate = state.newValue

                if state.newValue == nil {
                    self?.stopTimerUpdateTask()
                } else {
                    self?.startTimerUpdateTaskIfNeeded()
                }

                self?.setMenuItemTitle()
            }
            .store(in: &self.cancellables)

        Defaults.publisher(.tetheredButtonHideAllApps)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.setMenuItemTitle()
            }
            .store(in: &self.cancellables)

        if self.tetheredButtonHideAllAppsTimerDate != nil {
            self.startTimerUpdateTaskIfNeeded()
        }
    }

    deinit {
        self.timerUpdateTask?.cancel()
        self.timerUpdateTask = nil
    }

    // MARK: - States

    private var cancellables = Set<AnyCancellable>()
    private var tetheredButtonHideAllAppsTimerDate: Date? = Defaults[.tetheredButtonHideAllAppsTimerDate]
    private var timerUpdateTask: Task<Void, Never>? = nil
    private var currentTime: Date = Date()

    // MARK: - Private Variables

    private lazy var statusDot = self.drawStatusDot(NSColor.orange500)

    @MainActor
    private var remainingTimeString: String {
        guard let timerDate = self.tetheredButtonHideAllAppsTimerDate else { return "" }

        let timeInterval = timerDate.timeIntervalSince(self.currentTime)
        if timeInterval <= 0 { return String.localized("Expired", table: "MenuBar") }

        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60

        if minutes > 0 {
            return "\(minutes)m \(seconds)s"
        } else {
            return "\(seconds)s"
        }
    }

    @MainActor
    private var statusText: String {
        if self.isHideAllAppsTimerActive {
            return String.localized(" Hidden for %@", table: "MenuBar", remainingTimeString)
        } else if Defaults[.tetheredButtonHideAllApps] {
            return String.localized(" Hidden everywhere", table: "MenuBar")
        } else {
            return ""
        }
    }

    // MARK: - Private Functions

    @MainActor
    private func setMenuItemTitle() {
        if let timerDate = self.tetheredButtonHideAllAppsTimerDate {
            self.isHideAllAppsTimerActive = timerDate > self.currentTime
        } else {
            self.isHideAllAppsTimerActive = false
        }

        self.title = self.statusText
    }

    @MainActor
    private func startTimerUpdateTaskIfNeeded() {
        guard self.tetheredButtonHideAllAppsTimerDate != nil,
              self.timerUpdateTask == nil
        else {
            return
        }

        self.timerUpdateTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(0.5))
                if Task.isCancelled {
                    break
                }

                guard let self = self else { return }

                await MainActor.run {
                    self.currentTime = Date()

                    // Clean up expired timer
                    if let timerDate = self.tetheredButtonHideAllAppsTimerDate,
                       timerDate <= self.currentTime
                    {
                        Defaults[.tetheredButtonHideAllAppsTimerDate] = nil
                        Defaults[.tetheredButtonHideAllApps] = false
                    }

                    self.setMenuItemTitle()
                }
            }
        }
    }

    @MainActor
    private func stopTimerUpdateTask() {
        self.timerUpdateTask?.cancel()
        self.timerUpdateTask = nil
    }

    @MainActor
    @objc private func cancelHideTimer() {
        Defaults[.tetheredButtonHideAllAppsTimerDate] = nil
        Defaults[.tetheredButtonHideAllApps] = false
        self.setMenuItemTitle()
        self.stopTimerUpdateTask()
    }
}
