//
//  MenuBarAppStatus.swift
//  Onit
//
//  Created by Loyd Kim on 9/22/25.
//

import AppKit
import Combine

@MainActor
final class MenuBarAppStatus: MenuBarItemBase, NSMenuItemValidation {
    // MARK: - Initializer

    override func initializeProperties() {
        self.title = "" /// This is handled by `self.setContents()`
        self.action = #selector(handleStatusAction)
        self.keyEquivalent = ""
        self.target = self
    }

    override func runPostInitilizationSetup() {
        self.stopCountdownTimer()
        self.setMenuItemTitleAndStatusIcon()

        // Centralized observer for status changes
        NotificationCenter.default.publisher(for: AppState.statusDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setMenuItemTitleAndStatusIcon()
            }
            .store(in: &self.cancellables)
    }


    // MARK: - Conformance to `NSMenuItemValidation`

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        self.setMenuItemTitleAndStatusIcon()
        return self.isEnabled
    }

    // MARK: - States

    private var cancellables = Set<AnyCancellable>()
    private var countdownTimer: Timer? = nil

    // MARK: - Private Variables

    private lazy var redStatusDot = self.drawStatusDot(AppStatusDotColor.red.nsColor)
    private lazy var orangeStatusDot = self.drawStatusDot(AppStatusDotColor.orange.nsColor)
    private lazy var grayStatusDot = self.drawStatusDot(AppStatusDotColor.gray.nsColor)
    private lazy var greenStatusDot = self.drawStatusDot(AppStatusDotColor.green.nsColor)

    private let solidFontColor = NSColor.labelColor
    private let transparentFontColor = NSColor.secondaryLabelColor

    // MARK: - Private Functions

    private func getStatusDotImage(for dotColor: AppStatusDotColor) -> NSImage {
        switch dotColor {
        case .red:
            return redStatusDot
        case .orange:
            return orangeStatusDot
        case .gray:
            return grayStatusDot
        case .green:
            return greenStatusDot
        }
    }

    private func setMenuItemTitleAndStatusIcon() {
        let appState = AppState.shared
        let statusMessage = appState.statusMessage
        let dotColor = appState.statusDotColor

        // Handle countdown timer for temporary disables
        if statusMessage.requiresCountdown {
            if countdownTimer == nil {
                startCountdownTimer()
            }
        } else {
            stopCountdownTimer()
        }

        // Set font color based on actionability
        let fontColor = statusMessage.isActionable ? solidFontColor : transparentFontColor

        self.attributedTitle = NSAttributedString(
            string: " \(statusMessage.displayText)",
            attributes: [.foregroundColor: fontColor]
        )

        self.image = getStatusDotImage(for: dotColor)
        self.isEnabled = statusMessage.isActionable
    }

    private func startCountdownTimer() {
        guard countdownTimer == nil else { return }

        nonisolated(unsafe) weak var weakSelf = self
        let timer = Timer(
            timeInterval: 0.5,
            repeats: true
        ) { _ in
            Task { @MainActor in
                weakSelf?.setMenuItemTitleAndStatusIcon()
            }
        }

        RunLoop.main.add(timer, forMode: .eventTracking)
        countdownTimer = timer
    }

    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    @objc private func handleStatusAction() {
        AppState.shared.handleStatusAction()
    }

    // MARK: - Public Functions

    func removeSubscriptions() {
        stopCountdownTimer()
        cancellables.removeAll()
    }
}
