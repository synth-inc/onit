//
//  PanelStatePinnedManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 07/05/25.
//

import AppKit
import Combine
import Defaults
import PostHog
import SwiftUI

@MainActor
class PanelStatePinnedManager: PanelStateBaseManager, ObservableObject {
    
    // MARK: - Singleton instance

    static let shared = PanelStatePinnedManager()
    
    // MARK: - Properties
    
    var isResizingWindows: Bool = false
    
    private var lastScreenFrame = CGRect.zero
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    var attachedScreen: NSScreen?
    
    /// Dragging
    let dragManager = GlobalDragManager()
    var dragManagerCancellable: AnyCancellable?
    var draggingWindow: AXUIElement?
    
    // MARK: - Initializer
    
    private override init() {
        super.init()
        
        states = []
    }

    // MARK: - PanelStateManagerLogic
    
    override var isPanelMovable: Bool { false }

    override func start() {
        stop()

        let state = OnitPanelState()
        
        self.state = state
        states = [state]
        
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
        
        dragManagerCancellable = dragManager.$isDragging
            .sink { [weak self] isDragging in
                if !isDragging {
                    self?.onActiveWindowDragEnded()
                }
            }
        
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
        
        dragManager.startMonitoring()
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
        dragManager.stopMonitoring()
        dragManagerCancellable?.cancel()
        draggingWindow = nil
        
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
        AnalyticsManager.Panel.opened(displayMode: "pinned")
        
        hideTetherWindow()
        resetFramesOnAppChange()
        
        attachedScreen = NSScreen.mouse
        
        buildPanelIfNeeded(for: state)
        showPanel(for: state)
    }
    
    override func closePanel(for state: OnitPanelState) {
        AnalyticsManager.Panel.closed(displayMode: "pinned")
        
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
    
    func activateMouseScreen(forced: Bool = false) {
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
    
    func checkIfDragStarted(window: AXUIElement) -> Bool {
        guard dragManager.isDragging else { return false }
        guard draggingWindow == nil else { return true }
        
        draggingWindow = window
        
        return true
    }
    
    private func onActiveWindowDragEnded() {
        guard let window = draggingWindow else { return }
        
        draggingWindow = nil
        
        guard let mouseScreen = NSScreen.mouse,
              let panelScreen = state.panel?.screen else { return }
        
        if mouseScreen === panelScreen {
            resizeWindow(for: panelScreen, window: window, windowFrameChanged: true)
        } else {
            targetInitialFrames.removeValue(forKey: window)
        }
    }
    
    override func resetFramesOnAppChange() {
        print("resizeWindow - resetFramesOnAppChange called frames to reset: \(targetInitialFrames.count)")
        let panelWidth = state.panelWidth - (TetheredButton.width / 2) + 1
        if Defaults[.pinnedResizeMode] == .all {
            targetInitialFrames.forEach { element, initialFrame in
                if let currentFrame = element.getFrame(convertedToGlobalCoordinateSpace: true) {
                    // If the window is not on the panel screen, don't reset the frame
                    if let panelScreen = state.panel?.screen {
                        if let currentScreen = currentFrame.findScreen(),
                        currentScreen != panelScreen {
                            return
                        }
                    }
                    // We actually don't care about the initial frame here, we just want to add panelWidth back to the window. 
                    let newWidth = currentFrame.width + panelWidth
                    let newFrame = NSRect(origin: currentFrame.origin,
                                          size: NSSize(width: newWidth, height: currentFrame.height))
                    _ = element.setFrame(newFrame)
                }
            }
        } else {
            targetInitialFrames.forEach { element, initialFrame in
                // In Pinned mode, we should only reset the frame if it's still bordering the panel. 
                // Instead of using the initial frame, we should add panelWidth back to the window, so it goes all the way to the edge of the screen.

                if let currentFrame = element.getFrame() {
                    let screenFrame = NSScreen.main?.visibleFrame ?? .zero
                    let isNearPanel = abs((screenFrame.maxX - panelWidth) - currentFrame.maxX) <= 2
                    
                    if !isNearPanel {
                        return
                    }
                    let newWidth = currentFrame.width + panelWidth
                    let newFrame = NSRect(origin: currentFrame.origin,
                                          size: NSSize(width: newWidth, height: currentFrame.height))
                    print("resizeWindow - resetting initialFrame \(initialFrame)")
                    _ = element.setFrame(newFrame)
                }
            }
        }
        targetInitialFrames.removeAll()
    }
}
