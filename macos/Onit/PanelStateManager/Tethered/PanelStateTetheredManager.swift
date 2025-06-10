//
//  PanelStateTetheredManager.swift
//  Onit
//
//  Created by Kévin Naudin on 12/03/2025.
//

@preconcurrency import AppKit
import Combine
import Defaults
import PostHog
import SwiftUI

@MainActor
class PanelStateTetheredManager: PanelStateBaseManager, ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = PanelStateTetheredManager()
    
    // MARK: - Properties
    
    var statesByWindow: [TrackedWindow: OnitPanelState] = [:] {
        didSet {
            states = Array(statesByWindow.values)
        }
    }
    
    /// Dragging
    private let dragManager = GlobalDragManager()
    private var dragManagerCancellable: AnyCancellable?
    private var draggingState: OnitPanelState?
    
    // MARK: - Private initializer
    
    private override init() {
        super.init()
    }
    
    // MARK: - PanelStateManagerLogic
    
    override func start() {
        stop()
        
        AccessibilityNotificationsManager.shared.addDelegate(self)
        
        dragManagerCancellable = dragManager.$isDragging
            .sink { isDragging in
                if !isDragging {
                    self.onActiveWindowDragEnded()
                }
            }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        
        dragManager.startMonitoring()
    }
    
    override func stop() {
        AccessibilityNotificationsManager.shared.removeDelegate(self)
        NotificationCenter.default.removeObserver(self)
        dragManager.stopMonitoring()
        dragManagerCancellable?.cancel()
        draggingState = nil
        
        super.stop()
        
        statesByWindow = [:]
    }
    
    override func getState(for windowHash: UInt) -> OnitPanelState? {
        guard let (_, state) = statesByWindow.first(where: { $0.key.hash == windowHash }) else { return nil }
        
        return state
    }
    
    override func filterHistoryChats(_ chats: [Chat]) -> [Chat] {
        guard let appBundleIdentifier = state.trackedWindow?.pid.bundleIdentifier else {
            return super.filterHistoryChats(chats)
        }
        
        return chats.filter { chat in
            chat.appBundleIdentifier == appBundleIdentifier
        }
    }
    
    override func filterPanelChats(_ chats: [Chat]) -> [Chat] {
        guard let windowHash = state.trackedWindow?.hash else {
            return super.filterPanelChats(chats)
        }
        
        return chats.filter { chat in
            chat.windowHash == windowHash
        }
    }
    
    override func launchPanel(for state: OnitPanelState) {
        AnalyticsManager.Panel.opened(displayMode: "tethered", appName: appName(for: state))

        buildPanelIfNeeded(for: state)
        showPanel(for: state)
        if Defaults[.autoContextOnLaunchTethered] {
            fetchWindowContext()
        }
    }
    
    override func closePanel(for state: OnitPanelState) {
        AnalyticsManager.Panel.closed(displayMode: "tethered", appName: appName(for: state))
        
        hidePanel(for: state)
        
        super.closePanel(for: state)
    }

    override func fetchWindowContext() {
        guard let (trackedWindow, _) = statesByWindow.first(where: {
            $0.1 === self.state
        }) else { return }
        
        AccessibilityNotificationsManager.shared.fetchAutoContext(pid: trackedWindow.pid)
    }
    
    // MARK: - Functions
    
    @objc func appDidBecomeActive(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for (_, state) in self.statesByWindow {
                if let panel = state.panel, panel.isKeyWindow, let window = state.trackedWindow?.element {
                    window.bringToFront()
                    return
                }
            }
        }
    }
    
    @objc private func applicationWillTerminate() {
        resetFramesOnAppChange()
    }
    
    // MARK: - Handling panel state changes
    
    func handlePanelStateChange(state: OnitPanelState, action: TrackedWindowAction) {
        guard let window = state.trackedWindow?.element else {
            return
        }
        
        // We're now introducing a 3rd state.
        if !state.hidden {
            if state.panelOpened {
                // Panel opened
                var action = action
                
                if state.panelWasHidden {
                    tempShowPanel(state: state)
                }
                
                // TODO: KNA - We need to store the frame used to calculate the tetheredButtonYPosition and apply a diff
                // Quick fix - when resizing, center the TetheredButton
                if action == .resize {
                    state.tetheredButtonYPosition = nil
                } else if action == .move {
                    action = checkIfDragStarted(state: state)
                }
                
                KeyboardShortcutsManager.enable(modelContainer: SwiftDataContainer.appContainer)
                saveInitialFrameIfNeeded(for: window, state: state)
                hideTetherWindow()

                if state.currentAnimationTask == nil {
                    showPanel(for: state, action: action)
                }
            } else {
                // Panel closed
                KeyboardShortcutsManager.disable(modelContainer: SwiftDataContainer.appContainer)
                debouncedShowTetherWindow(state: state, activeWindow: window, action: action)
            }
        } else {
            // If it's hidden, we want to hide the tether window and potentially animate out the panel.
            if (state.panelOpened && !state.panelWasHidden) {
                tempHidePanel(state: state)
            }
            hideTetherWindow()
        }
        
        if let trackedWindow = state.trackedWindow {
            updateLevelState(trackedWindow: trackedWindow)
        }
    }
    
    func updateLevelState(trackedWindow: TrackedWindow?) {
        if let currentWindow = trackedWindow?.element,
           let currentWindowScreen = currentWindow.getFrame(convertedToGlobalCoordinateSpace: true)?.findScreen() {
            
            for (key, value) in statesByWindow {
                if let frame = key.element.getFrame(convertedToGlobalCoordinateSpace: true) {
                    // Do something on the frame
                    
                    if currentWindowScreen.frame.intersects(frame) {
                        /// Same screen
                        if key == trackedWindow {
                            value.panel?.setLevel(.floating)
                        } else {
                            value.panel?.setLevel(.normal)
                        }
                    } else { /** Window is not on same screen */ }
                } else { /** Can't find window's frame */ }
            }
        } else {
            /** Can't find current window - ignored apps */
            for (_, value) in statesByWindow {
                value.panel?.level = .normal
            }
        }
    }
    
    func getState(for trackedWindow: TrackedWindow) -> OnitPanelState {
        let panelState: OnitPanelState
        
        if let (_, activeState) = statesByWindow.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == trackedWindow
        }) {
            activeState.trackedWindow = trackedWindow
            panelState = activeState
        } else {
            panelState = OnitPanelState(trackedWindow: trackedWindow)
            
            statesByWindow[trackedWindow] = panelState
        }
        
        panelState.addDelegate(self)
        state = panelState
        
        return panelState
    }
    
    // MARK: - Private functions
    
    private func saveInitialFrameIfNeeded(for window: AXUIElement, state: OnitPanelState) {
        if targetInitialFrames[window] == nil,
                  let frame = window.getFrame(),
                  state.currentAnimationTask == nil {
            targetInitialFrames[window] = frame
        }
    }
    
    private func checkIfDragStarted(state: OnitPanelState) -> TrackedWindowAction {
        guard dragManager.isDragging else { return .moveAutomatically }
        guard draggingState == nil else { return .move }
        
        draggingState = state
        state.isWindowDragging = true
        state.panel?.alphaValue = 0.3
        
        return .move
    }
    
    private func onActiveWindowDragEnded() {
        guard let state = draggingState else { return }
        
        state.isWindowDragging = false
        draggingState = nil
        
        if let panel = state.panel {
            DispatchQueue.main.async {
                NSAnimationContext.runAnimationGroup { context in
                    context.duration = 0.1
                    panel.animator().alphaValue = 0.0
                } completionHandler: {
                    NSAnimationContext.runAnimationGroup { context in
                        context.duration = 0.25
                        panel.animator().alphaValue = 1.0
                    }
                }
            }
        }
        handlePanelStateChange(state: state, action: .moveEnd)
    }
    
    /// Used for analytics purpose
    private func appName(for state: OnitPanelState) -> String? {
        if let (trackedWindow, _) = statesByWindow.first(where: { $1 === state }) {
            return trackedWindow.element.appName()
        }
        
        return nil
    }
}
