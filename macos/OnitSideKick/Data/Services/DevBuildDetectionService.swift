//
//  DevBuildDetectionService.swift
//  Onit
//
//  Created by Kévin Naudin on 2026-02-03.
//

import AppKit
import Combine

/// Service that detects if a dev build (inc.synth.onit.sidekick.dev) is running.
/// Used by production builds to defer to the dev build when both are running.
/// This service only activates in Release builds.
@MainActor
final class DevBuildDetectionService: ObservableObject {

    // MARK: - Singleton

    static let shared = DevBuildDetectionService()

    // MARK: - Constants

    private let devBundleId = "inc.synth.onit.sidekick.dev"

    // MARK: - Published Properties

    /// Whether a dev build is currently running
    @Published private(set) var isDevBuildRunning: Bool = false

    // MARK: - Computed Properties

    /// Whether the current (production) build should defer to the dev build.
    /// Always returns false in DEBUG and BETA builds (neither defers to a dev build).
    var shouldDeferToDevBuild: Bool {
        #if DEBUG || ONIT_BETA
        return false
        #else
        return isDevBuildRunning
        #endif
    }

    // MARK: - Private Properties

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// Starts monitoring for dev build launch/termination.
    /// Only active in production Release builds (not DEBUG or BETA).
    func startMonitoring() {
        #if DEBUG || ONIT_BETA
        return
        #else
        // Check current state
        checkForDevBuild()

        // Observe app launches
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .filter { [weak self] app in app.bundleIdentifier == self?.devBundleId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.isDevBuildRunning = true
            }
            .store(in: &cancellables)

        // Observe app terminations
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)
            .compactMap { $0.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication }
            .filter { [weak self] app in app.bundleIdentifier == self?.devBundleId }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                // Double-check no other dev instance is running
                self?.checkForDevBuild()
            }
            .store(in: &cancellables)
        #endif
    }

    /// Stops monitoring for dev build.
    func stopMonitoring() {
        cancellables.removeAll()
    }

    // MARK: - Private Methods

    private func checkForDevBuild() {
        let runningApps = NSWorkspace.shared.runningApplications
        isDevBuildRunning = runningApps.contains { $0.bundleIdentifier == devBundleId }
    }
}
