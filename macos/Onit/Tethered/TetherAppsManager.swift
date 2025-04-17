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
    var states: [TrackedWindow: OnitPanelState] = [:]
    
    private let defaultState = OnitPanelState(trackedWindow: nil)
    
    private var regularAppCancellable: AnyCancellable?
    private var skipFirstRegularAppUpdate: Bool = true
    
    static let minOnitWidth: CGFloat = ContentView.idealWidth
    static let spaceBetweenWindows: CGFloat = -(TetheredButton.width / 2)
    
    var targetInitialFrames: [AXUIElement: CGRect] = [:]
    
    private let tetherWindow: NSWindow
    private var lastYComputed: CGFloat?
    private var lastOffset: CGFloat?
    
    private var showTetherDebounceTimer: Timer?
    private let showTetherDebounceDelay: TimeInterval = 0.1
    
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
        
        tetherWindow = window
        state = defaultState
    }
    
    // MARK: - Functions
    
    func startObserving() {
        stopObserving()
        
        regularAppCancellable = Defaults.publisher(.isRegularApp)
            .map(\.newValue)
            .sink(receiveValue: onChange(isRegularApp:))
        
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
    }
    
    func stopObserving() {
        regularAppCancellable?.cancel()
        regularAppCancellable = nil
        stopAllObservers()
        NotificationCenter.default.removeObserver(self)
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
    
    // MARK: - Private functions
    
    private func startAllObservers() {
        AccessibilityNotificationsManager.shared.addDelegate(self)
    }
    
    private func stopAllObservers() {
        AccessibilityNotificationsManager.shared.removeDelegate(self)
        hideTetherWindow()
    }
    
    private func onChange(isRegularApp: Bool) {
        if isRegularApp {
            startAllObservers()
        } else {
            stopAllObservers()
            resetFramesOnAppChange()
        }
        guard !skipFirstRegularAppUpdate else {
            skipFirstRegularAppUpdate = false
            return
        }
        
        // Close all panels without animations
        defaultState.panel?.hide()
        defaultState.panel = nil
        
        for (_, state) in states {
            state.panel?.hide()
            state.panel = nil
        }
        
        if !isRegularApp {
            hideTetherWindow()
            defaultState.launchPanel()
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
    
    // MARK: - Handling panel state changes
    
    private func handlePanelStateChange(state: OnitPanelState, action: TrackedWindowAction) {
        guard Defaults[.isRegularApp], let window = state.trackedWindow?.element else {
            return
        }
        
        // We're now introducing a 3rd state.
        if !state.hidden {
            if state.panelOpened {
                if state.panelWasHidden {
                    state.tempShowPanel()
                }
                // Panel opened
                KeyboardShortcutsManager.enable(modelContainer: SwiftDataContainer.appContainer)
                saveInitialFrameIfNeeded(for: window, state: state)
                hideTetherWindow()

                // TODO: KNA - Tethered - We should just move the panel without any animation
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
    
    private func saveInitialFrameIfNeeded(for window: AXUIElement, state: OnitPanelState) {
        if targetInitialFrames[window] == nil,
                  let frame = window.getFrame(),
                  state.currentAnimationTask == nil {
            
            targetInitialFrames[window] = frame
        }
    }

    // MARK: - Tether window management
    
    private func debouncedShowTetherWindow(
        state: OnitPanelState,
        activeWindow: AXUIElement,
        action: TrackedWindowAction
    ) {
        hideTetherWindow()
        let pendingTetherWindow = (state, activeWindow)

        showTetherDebounceTimer?.invalidate()
        showTetherDebounceTimer = Timer.scheduledTimer(withTimeInterval: showTetherDebounceDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.showTetherWindow(state: pendingTetherWindow.0, activeWindow: pendingTetherWindow.1, action: action)
            }
        }
    }
    
    func showTetherWindow(state: OnitPanelState, activeWindow: AXUIElement?, action: TrackedWindowAction) {
        let tetherView = ExternalTetheredButton(
            onDrag: { [weak self] translation in
                self?.tetheredWindowMoved(y: translation)
            }
        ).environment(\.windowState, state)
        
        let buttonView = NSHostingView(rootView: tetherView)
        tetherWindow.contentView = buttonView
        lastYComputed = nil
        
        updateTetherWindowPosition(for: activeWindow, action: action, lastYComputed: lastYComputed)
        
        tetherWindow.orderFrontRegardless()
    }
    
    private func hideTetherWindow() {
        showTetherDebounceTimer?.invalidate()
        showTetherDebounceTimer = nil
        
        tetherWindow.orderOut(nil)
        tetherWindow.contentView = nil
        lastYComputed = nil
    }
    
    func updateTetherWindowPosition(for window: AXUIElement?, action: TrackedWindowAction, lastYComputed: CGFloat? = nil) {
        guard let activeWindow = window,
              let activeWindowFrame = activeWindow.getFrame(convertedToGlobalCoordinateSpace: true) else {
            return
        }
        var positionX = activeWindowFrame.origin.x + activeWindowFrame.width - ExternalTetheredButton.containerWidth
        var optionalWindowFrame: CGRect?
        
        if Self.isFinder(activeWindow: activeWindow) {
            if Self.isFinderShowingDesktopOnly(activeWindow: activeWindow) {
                if let mouseScreen = NSRect(origin: NSEvent.mouseLocation, size: NSSize(width: 1, height: 1)).findScreen() {
                    let screenFrame = mouseScreen.visibleFrame
               
                    optionalWindowFrame = screenFrame
                    positionX = screenFrame.maxX - ExternalTetheredButton.containerWidth
                }
            } else {
                // These are clicks on the desktop. The appActivation logic gives us the most recent
                // Finder window, but it could be behind other windows or minimized, so we don't want
                // to move the hint to it.
                if let isMain = activeWindow.isMain(), let isMinimized = activeWindow.isMinimized() {
                    if !isMain || isMinimized {
                        print("This is a click on the desktop, remove tether window")
                        hideTetherWindow()
                        return
                    }
                }
            }
        }
        let windowFrame = optionalWindowFrame ?? activeWindowFrame
        
        var positionY: CGFloat
        if lastYComputed == nil {
            positionY = windowFrame.minY + (windowFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)
        } else {
            positionY = computeTetheredWindowY(windowFrame: windowFrame, offset: lastYComputed)
        }
        
        let mouseScreen = NSRect(origin: NSEvent.mouseLocation, size: NSSize(width: 1, height: 1)).findScreen()
        let activeScreen = action == .move ? mouseScreen : windowFrame.findScreen()
        if let activeScreen = activeScreen {
            let maxX = activeScreen.visibleFrame.maxX
            
            if positionX > maxX - ExternalTetheredButton.containerWidth {
                positionX = maxX - ExternalTetheredButton.containerWidth
            }
            
            let minY = activeScreen.visibleFrame.minY
            if positionY < minY {
                positionY = minY
            }
        }
        
        state.tetheredButtonYPosition = windowFrame.height -
            (positionY - windowFrame.minY) -
            ExternalTetheredButton.containerHeight + (TetheredButton.height / 2)
        
        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        
        tetherWindow.setFrame(frame, display: false)
    }
    
    func tetheredWindowMoved(y: CGFloat) {
        guard let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.activeTrackedWindow,
              var windowFrame = trackedWindow.element.getFrame(convertedToGlobalCoordinateSpace: true) else {
            return
        }
        
        if Self.isFinderShowingDesktopOnly(activeWindow: trackedWindow.element) {
            windowFrame = windowFrame.findScreen()?.visibleFrame ?? windowFrame
        }
        
        let lastYComputed = computeTetheredWindowY(windowFrame: windowFrame, offset: y)
        self.lastYComputed = lastYComputed
        
        state.tetheredButtonYPosition = windowFrame.height -
            (lastYComputed - windowFrame.minY) -
            ExternalTetheredButton.containerHeight + (TetheredButton.height / 2)

        let frame = NSRect(
            x: tetherWindow.frame.origin.x,
            y: lastYComputed,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        
        tetherWindow.setFrame(frame, display: true)
    }
    
    private func computeTetheredWindowY(windowFrame: NSRect, offset: CGFloat?) -> CGFloat {
        let maxY = windowFrame.maxY - ExternalTetheredButton.containerHeight
        let minY = windowFrame.minY

        var lastYComputed = self.lastYComputed ?? windowFrame.minY + (windowFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)

        if let offset = offset {
            lastYComputed -= offset
        }

        let finalOffset: CGFloat

        if lastYComputed > maxY {
            finalOffset = maxY
        } else if lastYComputed < minY {
            finalOffset = minY
        } else {
            finalOffset = lastYComputed
        }

        return finalOffset
    }
    
    static private func isFinder(activeWindow: AXUIElement?) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications

        if let finderAppPid = runningApps.first(where: { $0.bundleIdentifier == "com.apple.finder" })?.processIdentifier,
            let activeWindow = activeWindow {
            return activeWindow.pid() == finderAppPid
        }
        return false
    }
    
    static func isFinderShowingDesktopOnly(activeWindow: AXUIElement?) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        
        guard let finderAppPid = runningApps.first(where: { $0.bundleIdentifier == "com.apple.finder" })?.processIdentifier,
              let activeWindow = activeWindow,
              activeWindow.pid() == finderAppPid else {
            
            return false
        }
        
        return activeWindow.getWindows().first?.role() == "AXScrollArea"
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
    
    private func getState(for trackedWindow: TrackedWindow) -> OnitPanelState {
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
}

// MARK: - AccessibilityNotificationsDelegate

extension TetherAppsManager: AccessibilityNotificationsDelegate {
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        let panelState = getState(for: window)
        
        handlePanelStateChange(state: panelState, action: .activate)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {
        hideTetherWindow()
        updateLevelState(trackedWindow: window)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {
        print("didMinimizeWindow - tetherAppsSManager")
        if let (_, state) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == window
        }) {
            state.hidden = true
            handlePanelStateChange(state: state, action: .undefined)
            state.panelWasHidden = true
        }
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {
        print("didDEminimizeWindow - tetherAppsSManager")
        if let (_, state) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == window
        }) {
            state.hidden = false
            handlePanelStateChange(state: state, action: .resize)
            state.panelWasHidden = false
        }
    }
        
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {
        if let (_, state) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == window
        }) {
            state.closePanel()
            state.removeDelegate(self)
            states.removeValue(forKey: window)
        }
        
        hideTetherWindow()
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow?) {
        hideTetherWindow()
        updateLevelState(trackedWindow: window)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {
        let panelState = getState(for: window)
        
        handlePanelStateChange(state: panelState, action: .move)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {
        let panelState = getState(for: window)
        
        handlePanelStateChange(state: panelState, action: .resize)
    }
}

// MARK: - OnitPanelStateDelegate

extension TetherAppsManager: OnitPanelStateDelegate {
    func panelBecomeKey(state: OnitPanelState) {
        self.state = state
    }
    func panelStateDidChange(state: OnitPanelState) {
        handlePanelStateChange(state: state, action: .undefined)
    }
    
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) { }
}
