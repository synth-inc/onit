//
//  HintManager+Hover.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Public Functions: Hover Tracking Subscription
 * Private Functions: Update Hover State
 */

import AppKit

extension HintManager {
    // MARK: - Public Functions: Hover Tracking Subscription

    func startHoverTracking() {
        stopHoverTracking()

        localMouseEventMonitorForHoverTracking = NSEvent.addLocalMonitorForEvents(matching: [
            .mouseMoved,
            .mouseEntered,
            .mouseExited
        ]) { [weak self] event in
            self?.updateHoverState()
            return event
        }

        globalMouseEventMonitorForHoverTracking = NSEvent.addGlobalMonitorForEvents(matching: [
            .mouseMoved
        ]) { [weak self] _ in
            self?.updateHoverState()
        }

        /// Initial check.
        updateHoverState()
    }

    func stopHoverTracking() {
        if let localMonitor = localMouseEventMonitorForHoverTracking {
            NSEvent.removeMonitor(localMonitor)
            localMouseEventMonitorForHoverTracking = nil
        }
        
        if let globalMonitor = globalMouseEventMonitorForHoverTracking {
            NSEvent.removeMonitor(globalMonitor)
            globalMouseEventMonitorForHoverTracking = nil
        }
        
        hoverExitDebounceTimer = nil
        isHintHovered = false
    }

    // MARK: - Private Functions: Update Hover State

    /// Update hover state based on current mouse position relative to hint window frame
    private func updateHoverState() {
        let mouseLocation = NSEvent.mouseLocation
        let isHoveringHintWindow = hintWindow.frame.contains(mouseLocation)

        /// Mouse entered the hint window.
        if isHoveringHintWindow {
            hoverExitDebounceTimer = nil
            if !isHintHovered {
                isHintHovered = true
            }
        }
        /// Mouse left the hint window.
        else {
            if isHintHovered && hoverExitDebounceTimer == nil {
                hoverExitDebounceTimer = Timer.scheduledTimer(
                    withTimeInterval: hoverExitDebounceDelay,
                    repeats: false
                ) { [weak self] _ in
                    guard let self = self else { return }

                    let currentMouseLocation = NSEvent.mouseLocation
                    let mouseNotCurrentlyInHintWindow = !self.hintWindow.frame.contains(currentMouseLocation)

                    if mouseNotCurrentlyInHintWindow {
                        self.isHintHovered = false
                    }

                    self.hoverExitDebounceTimer = nil
                }
            }
        }
    }
}
