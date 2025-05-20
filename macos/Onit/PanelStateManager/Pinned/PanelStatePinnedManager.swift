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
    
    var statesByScreen: [NSScreen: OnitPanelState] = [:] {
        didSet {
            states = Array(statesByScreen.values)
        }
    }
    
    let spaceMonitoringManager = SpaceMonitoringManager()
    
    /// Dragging
    let dragManager = GlobalDragManager()
    var dragManagerCancellable: AnyCancellable?
    var draggingWindow: AXUIElement?
    
    // MARK: - Initializer
    
    private override init() {
        super.init()
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
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        spaceMonitoringManager.start { [weak self] screen in
            self?.spaceChangedReceived(screen: screen)
        }
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
        
        spaceMonitoringManager.stop()
        dragManager.stopMonitoring()
        dragManagerCancellable?.cancel()
        draggingWindow = nil
        
        super.stop()
        
        statesByScreen = [:]
    }
    
    override func getState(for window: AXUIElement) -> OnitPanelState? {
//        guard let windowFrameConverted = window.getFrame(convertedToGlobalCoordinateSpace: true),
//              let windowScreen = windowFrameConverted.findScreen() else { return nil }
//        
//        guard let (_, state) = statesByScreen.first(where: { $0.key === windowScreen }) else {
//            return nil
//        }
        
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
        
        hideTetherWindow()
        restoreFrames(for: state)
        
        buildPanel(for: state)
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
        guard let userInfo = notification.userInfo,
              let app = (userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication) ??
                      (userInfo["NSWorkspaceApplicationKey"] as? NSRunningApplication) else { return }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let windows = app.processIdentifier.findTargetWindows()
            
            for window in windows {
                if let windowFrameConverted = window.getFrame(convertedToGlobalCoordinateSpace: true),
                   let windowScreen = windowFrameConverted.findScreen(),
                   let (_, state) = self?.statesByScreen.first(where: { $0.key === windowScreen }) {
                    guard state.panelOpened else { break }
                    
                    self?.resizeWindow(for: state, window: window)
                }
            }
        }
    }
    
    private func spaceChangedReceived(screen: NSScreen) {
        guard let (_, state) = statesByScreen.first(where: { $0.key === screen }) else { return }
        
        guard state.panelOpened, let panel = state.panel else { return }
        
        panel.orderFrontRegardless()
        
        restoreFrames(for: state)
        resizeWindows(for: state)
    }

    @objc private func applicationWillTerminate() {
        restoreAllFrames()
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
    
    func checkIfDragStarted(window: AXUIElement) -> Bool {
        guard dragManager.isDragging else { return false }
        guard draggingWindow == nil else { return true }
        
        draggingWindow = window
        
        return true
    }
    
    private func handleActivation(of screen: NSScreen) {
        let panelState: OnitPanelState

        if let (_, activeState) = statesByScreen.first(where: { $0.key === screen} ) {
            activeState.trackedScreen = screen
            panelState = activeState
        } else {
            panelState = OnitPanelState(screen: screen)
            
            statesByScreen[screen] = panelState
        }

        panelState.addDelegate(self)
        state = panelState
        
        handlePanelStateChange(state: panelState)
    }
    
    private func onActiveWindowDragEnded() {
        guard let window = draggingWindow else { return }
        
        draggingWindow = nil
        
        guard let mouseScreen = NSScreen.mouse,
              let (_, state) = statesByScreen.first(where: { $0.key === mouseScreen }) else { return }
        
        if state.panelOpened {
            resizeWindow(for: state, window: window, windowFrameChanged: true)
        } else {
            targetInitialFrames.removeValue(forKey: window)
        }
    }
    
    func handlePanelStateChange(state: OnitPanelState) {
        guard let (screen, state) = statesByScreen.first(where: { $0.value === state }) else {
            return
        }

        if !state.hidden {
            if state.panelOpened {
                hideTetherWindow()
                
                showPanel(for: state)
            } else {
                debouncedShowTetherWindow(state: state, activeScreen: screen)
            }
        } else {
            // We can't hide the panel in pinned mode.
        }

        state.panel?.setLevel(.floating)
    }
}
