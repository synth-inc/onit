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
    
    var tutorialWindow: NSWindow
    
    // MARK: - Initializer
    
    private override init() {
        tutorialWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: (TetherTutorialOverlay.width * 1.5), height: (TetherTutorialOverlay.height * 1.5)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        tutorialWindow.isOpaque = false
        tutorialWindow.backgroundColor = NSColor.clear
        tutorialWindow.level = .floating
        tutorialWindow.hasShadow = false
        tutorialWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        tutorialWindow.isReleasedWhenClosed = false
        tutorialWindow.titlebarAppearsTransparent = true
        tutorialWindow.titleVisibility = .hidden
        tutorialWindow.standardWindowButton(.closeButton)?.isHidden = true
        tutorialWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        tutorialWindow.standardWindowButton(.zoomButton)?.isHidden = true
        
        let tutorialView = NSHostingView(rootView: TetherTutorialOverlay())
        tutorialWindow.contentView = tutorialView
        
        super.init()
        
        states = [defaultState]
    }

    // MARK: - Functions

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
    
    func resizeWindows(for screen: NSScreen) {
        let onitName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
        let appPids = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .filter { $0.localizedName != onitName }
            .map { $0.processIdentifier }
         
        for pid in appPids {
            let windows = pid.getWindows()
            
            for window in windows {
                resizeWindow(for: screen, window: window)
            }
        }
    }
    
    private func resizeWindow(for screen: NSScreen, window: AXUIElement) {
        guard !targetInitialFrames.keys.contains(window) else { return }
        
        if let windowFrameConverted = window.getFrame(convertedToGlobalCoordinateSpace: true),
           let windowScreen = windowFrameConverted.findScreen(),
           windowScreen == screen,
           let windowFrame = window.getFrame() {
            
            let panelWidth = ContentView.idealWidth - (TetheredButton.width / 2)
            let screenFrame = screen.visibleFrame
            let availableSpace = screenFrame.maxX - windowFrame.maxX
            
            if availableSpace < panelWidth {
                targetInitialFrames[window] = windowFrame
                
                let overlapAmount = panelWidth - availableSpace
                let newWidth = windowFrame.width - overlapAmount
                let newFrame = CGRect(x: windowFrame.origin.x, y: windowFrame.origin.y, width: newWidth, height: windowFrame.height)
                
                _ = window.setFrame(newFrame)
            }
        }
    }
    
    override func hideTetherWindow() {
        super.hideTetherWindow()
        
        tutorialWindow.orderOut(nil)
        tutorialWindow.contentView = nil
    }

    override func filterHistoryChats(_ chats: [Chat]) -> [Chat] {
        return super.filterHistoryChats(chats)
    }
    
    override func filterPanelChats(_ chats: [Chat]) -> [Chat] {
        return super.filterPanelChats(chats)
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
            resetFramesOnAppChange()
            
            state.trackedScreen = nil
            
            activateMouseScreen(forced: true)
        } else {
            state.panel?.setLevel(.floating)
        }
    }
    
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) {}
}
