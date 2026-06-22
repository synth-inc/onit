//
//  EscapeKeyManager.swift
//  Onit
//
//  Created by Kévin Naudin on 10/01/2025.
//

import AppKit
import Combine
import Defaults
import Foundation
import CoreGraphics

@MainActor
class EscapeKeyManager {
    
    // MARK: - Singleton instance
    
    static let shared = EscapeKeyManager()
    
    // MARK: - Properties
    
    private static let escapeKeyCode: Int64 = 53
    private var eventTap: CFMachPort?
    private var globalMonitor: Any?
    private var isEnabled = false

    // Dev build coexistence
    private var devBuildCancellables = Set<AnyCancellable>()
    private var wasEnabledBeforeDevBuild = false

    // MARK: - Private initializer

    private init() {}
    
    // MARK: - Public functions
    
    func startMonitoring() {
        guard !isEnabled else { return }
        
        isEnabled = true
        
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                guard let refcon = refcon else {
                    return Unmanaged.passUnretained(event)
                }
                
                let manager = Unmanaged<EscapeKeyManager>.fromOpaque(refcon).takeUnretainedValue()

                // Re-enable event tap if disabled by system
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let tap = manager.eventTap {
                        CGEvent.tapEnable(tap: tap, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }

                guard type == .keyDown else {
                    return Unmanaged.passUnretained(event)
                }

                let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

                guard keyCode == EscapeKeyManager.escapeKeyCode else {
                    return Unmanaged.passUnretained(event)
                }

                // Escape key pressed — callback runs on the main run loop,
                // so we can call @MainActor methods directly.
                let shouldConsume = manager.handleEscapeKeyWithPriority()

                return shouldConsume ? nil : Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let eventTap = eventTap else { return }
        
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        
        CGEvent.tapEnable(tap: eventTap, enable: true)
    }
    
    func stopMonitoring() {
        guard isEnabled else { return }
        
        isEnabled = false
        
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            CFMachPortInvalidate(eventTap)
            self.eventTap = nil
        }
    }

    // MARK: - Dev Build Coexistence

    /// Start observing dev build detection service (Release builds only)
    func observeDevBuildDetection() {
        #if !DEBUG
        DevBuildDetectionService.shared.$isDevBuildRunning
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDevBuildRunning in
                guard let self = self else { return }
                if isDevBuildRunning {
                    self.wasEnabledBeforeDevBuild = self.isEnabled
                    if self.isEnabled {
                        self.stopMonitoring()
                    }
                } else {
                    if self.wasEnabledBeforeDevBuild {
                        self.startMonitoring()
                    }
                }
            }
            .store(in: &devBuildCancellables)
        #endif
    }

    // MARK: - Private functions

    private func handleEscapeKeyWithPriority() -> Bool {
        // Close Panel if needed
        let enableSidebar = Defaults[.enableSidebar]
        let escapeShortcutDisabled = Defaults[.escapeShortcutDisabled]
        let isPinned = FeatureFlagManager.shared.usePinnedMode
        let isAppInForeground = NSApp.isActive
        let panelState = PanelStateCoordinator.shared.state
        let shouldDisableEscForPanel: Bool
        
        if isPinned {
            shouldDisableEscForPanel = !isAppInForeground || escapeShortcutDisabled
        } else {
            shouldDisableEscForPanel = escapeShortcutDisabled
        }

        if enableSidebar {
            if panelState.panelOpened && !shouldDisableEscForPanel {
                // If panel is already animating (closing), let Escape pass through
                if let panel = panelState.panel, panel.isAnimating {
                    return false
                }
                executeEscapeForPanel()

                return true
            }

            return false

        } else {
            return false
        }
    }
    
    private func executeEscapeForPanel() {
        let state = PanelStateCoordinator.shared.state
        
        if state.showContextMenuBrowserTabs {
            state.showContextMenuBrowserTabs = false
        } else if state.pendingInput != nil {
            state.pendingInput = nil
        } else {
            PanelStateCoordinator.shared.closePanel()
        }
    }
}
