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
    
    private var showTetherDebounceTimer: Timer?
    private let showTetherDebounceDelay: TimeInterval = 0.3
    
    // MARK: - Private initializer
    private init() {
        let window = NSWindow(
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
    }
    
    func stopObserving() {
        regularAppCancellable?.cancel()
        regularAppCancellable = nil
        stopAllObservers()
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
            guard let window = element.findWindow() else {
                return
            }
            
            _ = window.setFrame(initialFrame)
        }
        targetInitialFrames.removeAll()
    }
    
    // MARK: - Handling panel state changes
    
    private func handlePanelStateChange(state: OnitPanelState) {
        print("HandlePanelStateChange")
        guard let window = state.trackedWindow?.element else {
            return
        }
        
        if state.panelOpened && !state.panelMiniaturized {
            // Panel opened
            print("Panel opened and not miniaturized.")
            saveInitialFrameIfNeeded(for: window, state: state)
            hideTetherWindow()

            // TODO: KNA - Tethered - We should just move the panel without any animation
//            state.panel?.orderFront(nil)
            state.bringTrackedWindowToFront(trackedWindow: state.trackedWindow!)
            state.showPanel()
            
            state.repositionPanel()
        } else if !state.panelOpened {
            // Panel closed
            print("Panel closed.")
            debouncedShowTetherWindow(state: state, activeWindow: window)
        } else {
            // Panel minified
            print("Panel miniaturized.")
            debouncedShowTetherWindow(state: state, activeWindow: window)
        }
        
//        if let trackedWindow = state.trackedWindow {
//            print("Updating level state for tracked window.")
//            updateLevelState(trackedWindow: trackedWindow)
//        }
    }
    
    private func saveInitialFrameIfNeeded(for window: AXUIElement, state: OnitPanelState) {
        if targetInitialFrames[window] == nil,
                  let position = window.position(),
                  let size = window.size() {
            targetInitialFrames[window] = CGRect(
                x: position.x,
                y: position.y,
                width: size.width,
                height: size.height
            )
        }
    }

    // MARK: - Tether window management
    
    private func debouncedShowTetherWindow(state: OnitPanelState, activeWindow: AXUIElement) {
        hideTetherWindow()
        let pendingTetherWindow = (state, activeWindow)

        showTetherDebounceTimer?.invalidate()
        showTetherDebounceTimer = Timer.scheduledTimer(withTimeInterval: showTetherDebounceDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.showTetherWindow(state: pendingTetherWindow.0, activeWindow: pendingTetherWindow.1)
            }
        }
    }
    
    func showTetherWindow(state: OnitPanelState, activeWindow: AXUIElement?) {
        let tetherView = ExternalTetheredButton(
            onDrag: { [weak self] translation in
                self?.tetheredWindowMoved(y: translation)
            }
        ).environment(\.windowState, state)
        
        let buttonView = NSHostingView(rootView: tetherView)
        tetherWindow.contentView = buttonView
        lastYComputed = nil
        
        updateTetherWindowPosition(for: activeWindow, lastYComputed: lastYComputed)
        
        tetherWindow.orderFront(nil)
    }
    
    private func hideTetherWindow() {
        showTetherDebounceTimer?.invalidate()
        showTetherDebounceTimer = nil
        
        tetherWindow.orderOut(nil)
        tetherWindow.contentView = nil
        lastYComputed = nil
    }
    
    func updateTetherWindowPosition(for window: AXUIElement?, lastYComputed: CGFloat? = nil) {
        guard let activeWindow = window,
              var windowFrame = activeWindow.frame(),
              let size = activeWindow.size(),
              let position = activeWindow.position() else {
            return
        }
        var positionX = position.x + size.width - ExternalTetheredButton.containerWidth
        
        if Self.isFinderShowingDesktopOnly(activeWindow: activeWindow) {
            if let mouseScreen = NSRect(origin: NSEvent.mouseLocation, size: NSSize(width: 1, height: 1)).findScreen() {
                let screenFrame = mouseScreen.visibleFrame
                
                windowFrame = screenFrame
                positionX = screenFrame.maxX - ExternalTetheredButton.containerWidth
            }
        }
        
        let lastYComputed = lastYComputed ?? getCenterPositionY(for: windowFrame) ?? 0
        
        if let distanceFromBottom = calculateWindowDistanceFromBottom(for: windowFrame) {
            state.tetheredButtonYPosition = distanceFromBottom + windowFrame.height - lastYComputed - ExternalTetheredButton.containerHeight
        }

        // This prevents the hint from going beyond the edge of the current screen
        // This can happen when the window is between two screens. 
        if let activeScreen = windowFrame.findScreen() {
            let maxX = activeScreen.visibleFrame.maxX
            if positionX > maxX {
                positionX = maxX - ExternalTetheredButton.containerWidth
            }
        }
        
        let frame = NSRect(
            x: positionX,
            y: lastYComputed,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        tetherWindow.setFrame(frame, display: true)
    }
    
    func tetheredWindowMoved(y: CGFloat) {
        guard let trackedWindow = AccessibilityNotificationsManager.shared.windowsManager.activeTrackedWindow else {
            return
        }
        
        guard var windowFrame = trackedWindow.element.frame() else { return }
        
        if Self.isFinderShowingDesktopOnly(activeWindow: trackedWindow.element) {
            windowFrame = windowFrame.findScreen()?.visibleFrame ?? windowFrame
        }
        
        lastYComputed = computeTetheredWindowY(windowFrame: windowFrame, offset: y)
        updateTetherWindowPosition(for: trackedWindow.element, lastYComputed: lastYComputed)
    }
    
    private func computeTetheredWindowY(windowFrame: NSRect, offset: CGFloat?) -> CGFloat? {
        guard let maxY = getMaxY(for: windowFrame),
              var minY = getMinY(for: windowFrame) else { return nil }
        
        var lastYComputed = self.lastYComputed ?? (getCenterPositionY(for: windowFrame) ?? 0)
        
        if minY < ContentView.bottomPadding {
            minY = ContentView.bottomPadding
        }
        
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
    
    private func getMaxY(for windowFrame: NSRect) -> CGFloat? {
        guard let distanceFromBottom = calculateWindowDistanceFromBottom(for: windowFrame) else {
            return nil
        }
        return distanceFromBottom + windowFrame.height - ExternalTetheredButton.containerHeight
    }

    private func getMinY(for windowFrame: NSRect) -> CGFloat? {
        return calculateWindowDistanceFromBottom(for: windowFrame) ?? nil
    }

    private func getCenterPositionY(for windowFrame: NSRect) -> CGFloat? {
        guard let distanceFromBottom = calculateWindowDistanceFromBottom(for: windowFrame) else {
            return nil
        }
        return distanceFromBottom + (windowFrame.height / 2.0) - (ExternalTetheredButton.containerHeight / 2.0)
    }
    
    private func calculateWindowDistanceFromBottom(for windowFrame: NSRect) -> CGFloat? {
        guard let activeScreen = windowFrame.findScreen() else { return nil }
        
        // Find the primary screen (the one with origin at 0,0)
        let screens = NSScreen.screens
        let primaryScreen = screens.first { screen in
            screen.frame.origin.x == 0 && screen.frame.origin.y == 0
        } ?? NSScreen.main ?? screens.first!
        
        // VisibleFrame subtracts the dock and toolbar. Frame is the whole screen.
        let activeScreenFrame = activeScreen.frame
        let activeScreenVisibileFrame = activeScreen.visibleFrame
        let primaryScreenFrame = primaryScreen.frame
        
        // This is the height of the dock and/or toolbar.
        let activeScreenInset = activeScreenFrame.height - activeScreenVisibileFrame.height
        
        // This is the maximum possible Y value a window can occupy on a given screen.
        let fullTop = primaryScreenFrame.height - activeScreenFrame.height - activeScreenVisibileFrame.minY + activeScreenInset
        
        // This is how far down the window is from the max possibile position.
        let windowDistanceFromTop = windowFrame.minY - fullTop
        return activeScreenVisibileFrame.minY + (activeScreenVisibileFrame.height - windowFrame.height) - windowDistanceFromTop
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
//        if let currentWindow = trackedWindow?.element,
//           let currentWindowPosition = currentWindow.position(),
//           let currentWindowSize = currentWindow.size() {
//            let currentWindowFrame = NSRect(origin: currentWindowPosition, size: currentWindowSize)
//                        
//            if let currentWindowScreen = currentWindowFrame.dominantScreen() {
//                for (key, value) in states {
//                    if let position = key.element.position(), let size = key.element.size() {
//                        let frame = NSRect(origin: position, size: size)
//                        
//                        if currentWindowScreen.frame.intersects(frame) {
//                            /// Same screen
//                            if key == trackedWindow {
//                                value.panel?.level = .floating
//                            } else if value.panel?.level == .floating {
//                                value.panel?.level = .normal
//                                value.panel?.orderBack(nil)
//                            } else {
//                                value.panel?.orderBack(nil)
//                            }
//                        } else { /** Window is not on same screen */ }
//                    } else { /** Can't find window's frame */ }
//                }
//            } else { /** Can't find current window's screen */ }
//        } else {
//            /** Can't find current window - ignored apps */
//            for (_, value) in states {
//                value.panel?.level = .normal
//                value.panel?.orderBack(nil)
//            }
//        }
    }
}

// MARK: - AccessibilityNotificationsDelegate

extension TetherAppsManager: AccessibilityNotificationsDelegate {
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        print("didActivateWindow")
        let panelState: OnitPanelState
        
        if let (_, activeState) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == window
        }) {
            activeState.trackedWindow?.title = window.title
            panelState = activeState
        } else {
            panelState = OnitPanelState(trackedWindow: window)
            
            states[window] = panelState
        }
        
        panelState.addDelegate(self)
        state = panelState
        handlePanelStateChange(state: panelState)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActiveWindowsProcess windows: [TrackedWindow]) {
        for window in windows {
            if let (_, state) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
                key == window
            }) {
                if state.panelOpened && !state.panelMiniaturized {
                    state.bringTrackedWindowToFront(trackedWindow: window)
                    state.showPanel()
                }
            }
        }
    }
    
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {
        hideTetherWindow()
        updateLevelState(trackedWindow: window)
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
}

// MARK: - OnitPanelStateDelegate

extension TetherAppsManager: OnitPanelStateDelegate {
    func panelStateDidChange(state: OnitPanelState) {
        handlePanelStateChange(state: state)
    }
    
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) { }
}
