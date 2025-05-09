//
//  TetherAppsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 12/03/2025.
//

@preconcurrency import AppKit
import Combine
import Defaults
import SwiftUI

@MainActor
class TetherAppsManager: ObservableObject {
    
    // MARK: - Singleton instance
    
    static let shared = TetherAppsManager()
    
    // MARK: - Properties
    
    @Published var state: OnitPanelState
    @Published var tetherButtonPanelState: OnitPanelState?
    var states: [TrackedWindow: OnitPanelState] = [:]
    
    /// Dragging
    private let dragManager = GlobalDragManager()
    private var dragManagerCancellable: AnyCancellable?
    private var draggingState: OnitPanelState?
    
    private let defaultState = OnitPanelState(trackedWindow: nil)
    
    static let spaceBetweenWindows: CGFloat = -(TetheredButton.width / 2)
    
    var targetInitialFrames: [AXUIElement: CGRect] = [:]
   
    var tetherHintDetails: TetherHintDetails
    
    // MARK: - Private initializer
    private init() {
        class CustomWindow: NSWindow {
            override var canBecomeKey: Bool { true }
        }
        let window = CustomWindow(
            contentRect: NSRect(x: 0, y: 0, width: ExternalTetheredButton.containerWidth, height: ExternalTetheredButton.containerHeight),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        window.isOpaque = false
        window.backgroundColor = NSColor.clear
        window.level = .floating
        window.hasShadow = false
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isReleasedWhenClosed = false
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        
        tetherHintDetails = TetherHintDetails(tetherWindow: window)
        state = defaultState
    }
    
    // MARK: - Functions
    
    func startObserving() {
        stopObserving()
        
        startAllObservers()
        
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
    
    func stopObserving() {
        stopAllObservers()
        NotificationCenter.default.removeObserver(self)
        dragManager.stopMonitoring()
        
        closePanels()
        hideTetherWindow()
        
        state = defaultState
        tetherButtonPanelState = nil
        states = [:]
        targetInitialFrames = [:]
    }
    
    @objc func appDidBecomeActive(_ notification: Notification) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            for (_, state) in self.states {
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
                    state.tempShowPanel()
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
                    state.repositionPanel(action: action)
                }
            } else {
                // Panel closed
                KeyboardShortcutsManager.disable(modelContainer: SwiftDataContainer.appContainer)
                debouncedShowTetherWindow(state: state, activeWindow: window, action: action)
            }
        } else {
            // If it's hidden, we want to hide the tether window and potentially animate out the panel.
            if (state.panelOpened && !state.panelWasHidden) {
                state.tempHidePanel()
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
            
            for (key, value) in states {
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
            for (_, value) in states {
                value.panel?.level = .normal
            }
        }
    }
    
    func getState(for trackedWindow: TrackedWindow) -> OnitPanelState {
        let panelState: OnitPanelState
        
        if let (_, activeState) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == trackedWindow
        }) {
            activeState.trackedWindow = trackedWindow
            panelState = activeState
        } else {
            panelState = OnitPanelState(trackedWindow: trackedWindow)
            
            states[trackedWindow] = panelState
        }
        
        panelState.addDelegate(self)
        state = panelState
        
        return panelState
    }
    
    // MARK: - Private functions
    
    private func startAllObservers() {
        AccessibilityNotificationsManager.shared.addDelegate(self)
    }
    
    private func stopAllObservers() {
        AccessibilityNotificationsManager.shared.removeDelegate(self)
        hideTetherWindow()
    }
    
    private func closePanels() {
        // Close all panels without animations
        defaultState.panel?.hide()
        defaultState.panel = nil
        
        for (_, state) in states {
            state.panel?.hide()
            state.panel = nil
        }
    }
    
    private func resetFramesOnAppChange() {
        targetInitialFrames.forEach { element, initialFrame in
            guard let window = element.findFirstTargetWindow() else {
                return
            }
            
            _ = window.setFrame(initialFrame)
        }
        targetInitialFrames.removeAll()
    }
    
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
    
}
