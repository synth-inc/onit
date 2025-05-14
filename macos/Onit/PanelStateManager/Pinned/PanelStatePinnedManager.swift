//
//  PanelStatePinnedManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 07/05/25.
//

import AppKit
import Defaults
import SwiftUI

@MainActor
class PanelStatePinnedManager: PanelStateBaseManager, ObservableObject {
    
    // MARK: - Singleton instance

    static let shared = PanelStatePinnedManager()
    
    // MARK: - Properties
    
    private var lastScreenFrame = CGRect.zero
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
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
        if state.trackedScreen != screen {
            debouncedShowTetherWindow(activeScreen: screen)
        } else {
            hideTetherWindow()
        }
    }
    
    func resizeWindows(for screen: NSScreen, isResize: Bool = false) {
        let onitName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        let appPids = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .filter { $0.localizedName != onitName }
            .map { $0.processIdentifier }
         
        for pid in appPids {
            let windows = pid.getWindows()
            
            for window in windows {
                resizeWindow(for: screen, window: window, isResize: isResize)
            }
        }
    }
    
    private func resizeWindow(for screen: NSScreen, window: AXUIElement, isResize: Bool = false) {
        if !isResize { guard !targetInitialFrames.keys.contains(window) else { return } }
        
        if let windowFrameConverted = window.getFrame(convertedToGlobalCoordinateSpace: true),
           let windowScreen = windowFrameConverted.findScreen(),
           windowScreen == screen,
           let windowFrame = window.getFrame() {
            
            let panelWidth = state.panelWidth - (TetheredButton.width / 2) + 1
            let screenFrame = screen.visibleFrame
            let availableSpace = screenFrame.maxX - windowFrame.maxX
            
            if !isResize {
                if availableSpace < panelWidth {
                    targetInitialFrames[window] = windowFrame
                    let overlapAmount = panelWidth - availableSpace
                    let newWidth = windowFrame.width - overlapAmount
                    let newFrame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: newWidth, height: windowFrame.height)
                    _ = window.setFrame(newFrame)
                }
            } else {
                // If we're already tracking it, then make it move.
                if targetInitialFrames.keys.contains(window) {
                    let newWidth = (screenFrame.maxX - windowFrame.origin.x) - panelWidth
                    let newFrame = CGRect(x: windowFrame.origin.x, y:windowFrame.origin.y, width: newWidth, height: windowFrame.height)
                    _ = window.setFrame(newFrame)
                } else if availableSpace < panelWidth {
                    // If we aren't already tracking it and it now needs to get resized, start tracking it.
                    targetInitialFrames[window] = windowFrame
                    let overlapAmount = panelWidth - availableSpace
                    let newWidth = windowFrame.width - overlapAmount
                    let newFrame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: newWidth, height: windowFrame.height)
                    _ = window.setFrame(newFrame)
                }
                
            }
        }
    }
}

extension PanelStatePinnedManager: AccessibilityNotificationsDelegate {
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        guard state.panelOpened, let screen = state.panel?.screen else { return }
        
        resizeWindow(for: screen, window: window.element)
    }
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
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
