//
//  HintManager+Visibility.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Public Variables
 * Functions: `shouldShowHint` Helpers
 * Functions: Pop-Up Auto-Dismiss
 * Functions: Visibility Evaluation
 */

import AppKit
import Defaults

extension HintManager {
    // MARK: - Public Variables

    var shouldShowHint: Bool {
        // Production build defers to dev build when both are running
        #if !DEBUG
        if DevBuildDetectionService.shared.shouldDeferToDevBuild {
            return false
        }
        #endif
        
        if Defaults[.alwaysHideHint] {
            return computeForceShowHint() /// Showing hint under special circumstances, like surfacing an error.
        } else {
            return computeBaseVisibility()
        }
    }
    
    // MARK: - Functions: `shouldShowHint` Helpers
    
    private func computeBaseVisibility() -> Bool {
        if OnboardingWindowManager.shared.onboardingWindowIsVisible {
            return false
        } else {
            return Defaults[.enableSidebar]
        }
    }

    /// The hint should be force-shown to the user in special circumstances.
    ///     For example, surfacing error messages or critical reminders (e.g. losing accessibility access, completing onboarding setups)
    private func computeForceShowHint() -> Bool {
        updateActivePopUpType()

        /// Hover doesn't currently count as a force-show.
        return activePopUpType != nil && activePopUpType != .hover
    }

    func updateActivePopUpType() {
        if shouldShowAccessibilityLostPopUpMessage {
            activePopUpType = .accessibilityLost
        }
        /// Commented out for now until non-AX becomes the default state.
//        else if shouldShowScreenRecordingLostPopUpMessage {
//            activePopUpType = .screenRecordingLost
//        }
        else if shouldShowUpdateAvailablePopUpMessage {
            activePopUpType = .updateAvailable
        } else {
            activePopUpType = nil
        }

        schedulePopUpAutoDismissIfNeeded()
    }

    // MARK: - Functions: Pop-Up Auto-Dismiss

    private func schedulePopUpAutoDismissIfNeeded() {
        guard let autoDismissDuration = activePopUpType?.autoDismissDuration
        else {
            cancelPopUpAutoDismissTask()
            return
        }

        /// Don't restart the timer if one is already running.
        guard popUpAutoDismissTask == nil else { return }

        popUpAutoDismissTask = Task { @MainActor [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: autoDismissDuration)
            guard !Task.isCancelled else { return }
            self.dismissPopUp()
        }
    }

    func cancelPopUpAutoDismissTask() {
        popUpAutoDismissTask?.cancel()
        popUpAutoDismissTask = nil
    }

    func dismissPopUp() {
        guard let activePopUpType = self.activePopUpType else { return }

        switch activePopUpType {
        case .updateAvailable:
            Defaults[.dismissedUpdateAlertVersion] = AppState.shared.availableUpdateVersion ?? ""
        case .accessibilityLost,
            /// Commented out for now until non-AX becomes the default state.
//                .screenRecordingLost,
                .hover:
            break
        }

        hideMoreMenu()
        refreshPopUp()
    }

    func refreshPopUp() {
        cancelPopUpAutoDismissTask()
        updateActivePopUpType()
        evaluateVisibility()
    }
    
    // MARK: - Functions: Visibility Evaluation
    
    func evaluateVisibility() {
        if shouldShowHint {
            guard !hintWindowIsVisible else { return }
            requestShowHint()
        } else {
            hideHint()
        }
    }

    private func requestShowHint() {
        let coordinator = PanelStateCoordinator.shared

        /// Tethered Mode
        if let tetheredManager = coordinator.currentManager as? PanelStateTetheredManager {
            if let pid = NSWorkspace.shared.frontmostApplication?.processIdentifier,
               let tracked = AccessibilityNotificationsManager.shared.windowsManager.trackWindowForElement(
                   pid.getAXUIElement(),
                   pid: pid
               ) {
                let state = tetheredManager.getState(for: tracked)
                tetheredManager.handlePanelStateChange(state: state, action: .activate)
            }
        }
        /// Pinned Mode
        else if let pinnedManager = coordinator.currentManager as? PanelStatePinnedManager {
            pinnedManager.activateMouseScreen(forced: true)
        }
        /// Untethered Mode
        else if let untetheredManager = coordinator.currentManager as? PanelStateUntetheredManager {
            if let screen = NSScreen.mouse {
                let state = untetheredManager.getState(for: screen)
                untetheredManager.debouncedShowTetherWindow(state: state, activeScreen: screen)
            }
        }
    }
    
    func hideHint() {
        showDebounceTimer = nil
        currentPanelState = nil
        currentScreen = nil

        stopHoverTracking()

        hideMoreMenu()

        /// Remove frame change observer before clearing content view.
        /// See `configureFrameChangeObserver()`.
        if let contentView = hintWindow.contentView {
            NotificationCenter.default.removeObserver(
                self,
                name: NSView.frameDidChangeNotification,
                object: contentView
            )
        }
        hintWindow.orderOut(nil)
        hintWindow.contentView = nil
    }
}
