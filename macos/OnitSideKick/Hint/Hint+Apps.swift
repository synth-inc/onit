//
//  Hint+Apps.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Private Variables
 * Public Functions
 * Private Functions
 */

import Foundation

extension Hint {
    // MARK: - Private Variables
    
    private var foregroundWindowAppName: String? {
        if let window = FeatureFlagManager.shared.usePinnedMode
            ? windowState?.foregroundWindow
            : windowState?.trackedWindow {
            return WindowHelpers.getWindowAppName(window: window.element)
        } else {
            return nil
        }
    }

    private var hideAllAppsCountdownIsActive: Bool {
        hideAllAppsTimer != nil && tetheredButtonHideAllAppsTimerDate != nil
    }

    private var isHidingAllApps: Bool {
        tetheredButtonHideAllApps || hideAllAppsCountdownIsActive
    }

    private var foregroundWindowIconHidden: Bool {
        if let appName = foregroundWindowAppName,
           checkCurrentAppIsHidden(appName)
        {
            return true
        } else {
            return isHidingAllApps
        }
    }
    
    // MARK: - Public Functions
    
    func toggleHideForegroundWindowIconsForOneHour() {
        let oneHourInSeconds: TimeInterval = 3600
        tetheredButtonHideAllAppsTimerDate = Date(timeIntervalSinceNow: oneHourInSeconds)

        clearHideAllAppsTimer()
        initializeHideAllAppsTimer()

        tetheredButtonHideAllApps = true

        hideMoreMenu()
    }
    
    func initializeHideAllAppsTimer() {
        let dateNow = Date()

        guard let hideAllAppsTimerDate = tetheredButtonHideAllAppsTimerDate,
              hideAllAppsTimerDate >= dateNow
        else {
            tetheredButtonHideAllAppsTimerDate = nil
            return
        }

        hideAllAppsTimer = Timer.scheduledTimer(
            withTimeInterval: hideAllAppsTimerDate.timeIntervalSince(dateNow),
            repeats: false
        ) { _ in
            Task { @MainActor in
                tetheredButtonHideAllAppsTimerDate = nil
                tetheredButtonHideAllApps = false
            }
        }
    }

    func clearHideAllAppsTimer() {
        hideAllAppsTimer?.invalidate()
        hideAllAppsTimer = nil
    }
    
    // MARK: - Private Functions
    
    private func toggleHideForegroundWindowIcons() {
        tetheredButtonShowAppIcons.toggle()
        hideMoreMenu()
    }
    
    private func toggleHideCurrentForegroundWindowIcon(appName: String) {
        let appIsHidden = checkCurrentAppIsHidden(appName)

        if appIsHidden {
            tetheredButtonHiddenApps.removeValue(forKey: appName)
        } else {
            tetheredButtonHiddenApps[appName] = true
        }

        hideMoreMenu()
    }

    private func checkCurrentAppIsHidden(_ appName: String) -> Bool {
        tetheredButtonHiddenApps[appName] != nil
    }
}
