//
//  PanelStatePinnedManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 07/05/25.
//

import AppKit
import Defaults
import PostHog
import SwiftUI

@MainActor
class PanelStatePinnedManager: PanelStateBaseManager, ObservableObject {
    
    // MARK: - Singleton instance

    static let shared = PanelStatePinnedManager()
    
    // MARK: - Properties
    
    private var isResizingWindows: Bool = false
    private var lastScreenFrame = CGRect.zero
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    var attachedScreen: NSScreen?
    
    // MARK: - Initializer
    
    private override init() {
        super.init()
        
        states = [defaultState]
    }

    // MARK: - PanelStateManagerLogic
    
    override var isPanelMovable: Bool { false }

    override func start() {
        stop()

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            activateMouseScreen()
        }
        
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return event }
            activateMouseScreen()
            return event
        }
        
        AccessibilityNotificationsManager.shared.addDelegate(self)
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunchedReceived),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceChangedReceived),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        
        state.addDelegate(self)
        
        activateMouseScreen(forced: true)
    }

    override func stop() {
        if let globalMouseMonitor = globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        if let localMouseMonitor = localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
        lastScreenFrame = .zero
        AccessibilityNotificationsManager.shared.removeDelegate(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        
        state.removeDelegate(self)
        
        super.stop()
    }
    
    override func getState(for windowHash: UInt) -> OnitPanelState? {
        return state
    }
    
    override func filterHistoryChats(_ chats: [Chat]) -> [Chat] {
        return super.filterHistoryChats(chats)
    }
    
    override func filterPanelChats(_ chats: [Chat]) -> [Chat] {
        return super.filterPanelChats(chats)
    }
    
    override func launchPanel(for state: OnitPanelState) {
        PostHogSDK.shared.capture("launch_panel", properties: ["displayMode": "pinned"])
        
        super.launchPanel(for: state)
        
        hideTetherWindow()
        resetFramesOnAppChange()
        
        attachedScreen = NSScreen.mouse
        
        showPanel(for: state)
    }
    
    override func closePanel(for state: OnitPanelState) {
        hidePanel(for: state)
        
        super.closePanel(for: state)
    }

    override func fetchWindowContext() {
        AccessibilityNotificationsManager.shared.fetchAutoContext()
    }
    
    // MARK: - Functions
    
    @objc private func appLaunchedReceived(notification: Notification) {
        guard state.panelOpened, let screen = state.panel?.screen, let userInfo = notification.userInfo else { return }
        
        guard let app = (userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication) ??
                (userInfo["NSWorkspaceApplicationKey"] as? NSRunningApplication) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let windows = app.processIdentifier.getWindows()
            
            for window in windows {
                self?.resizeWindow(for: screen, window: window)
            }
        }
    }
    
    @objc private func spaceChangedReceived(notification: Notification) {
        guard state.panelOpened, let panel = state.panel, let screen = panel.screen else { return }
        
        panel.orderFrontRegardless()
        
        resetFramesOnAppChange()
        resizeWindows(for: screen)
    }

    @objc private func applicationWillTerminate() {
        resetFramesOnAppChange()
    }
    
    private func activateMouseScreen(forced: Bool = false) {
        if forced {
            lastScreenFrame = .zero
        }
        if let mouseScreen = NSScreen.mouse {
            if !mouseScreen.frame.equalTo(lastScreenFrame) {
                handleActivation(of: mouseScreen)
                lastScreenFrame = mouseScreen.frame
            }
        }
    }
    
    private func handleActivation(of screen: NSScreen) {
        if attachedScreen != screen {
            debouncedShowTetherWindow(activeScreen: screen)
        } else {
            hideTetherWindow()
        }
    }
}

extension PanelStatePinnedManager: AccessibilityNotificationsDelegate {
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        guard state.panelOpened, let screen = state.panel?.screen else { return }
        
        /// Introduce a delay, as changing spaces causes simultaneous resizing, resulting in a visual glitch:
        /// 1. The app is resized first by this function from Accessibility
        /// 2. Then by the NSWorkspace.activeSpaceDidChangeNotification
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.resizeWindow(for: screen, window: window.element)
        }
    }
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {
        
    }
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {
        guard state.panelOpened, let screen = state.panel?.screen else { return }
        
        // This avoid simultaneous calls when closing the panel which restore the window's frame
        guard state.panel?.isAnimating == false else { return }
        
        resizeWindow(for: screen, window: window.element, windowFrameChanged: true)
    }
}

extension PanelStatePinnedManager: OnitPanelStateDelegate {
    func panelBecomeKey(state: OnitPanelState) {
        self.state = state
        KeyboardShortcutsManager.enable(modelContainer: SwiftDataContainer.appContainer)
    }
    
    func panelResignKey(state: OnitPanelState) {
        KeyboardShortcutsManager.disable(modelContainer: SwiftDataContainer.appContainer)
    }
    
    func panelStateDidChange(state: OnitPanelState) {
        if !state.panelOpened {
            // resetFramesOnAppChange()
            
            state.trackedScreen = nil
            
            activateMouseScreen(forced: true)
        } else {
            state.panel?.setLevel(.floating)
        }
    }
    
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) {}
}
