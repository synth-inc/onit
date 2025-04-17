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
        
        if state.panelOpened && !state.panelMiniaturized {
            // Panel opened
            
            KeyboardShortcutsManager.enable(modelContainer: SwiftDataContainer.appContainer)
            saveInitialFrameIfNeeded(for: window, state: state)
            
            if state.currentAnimationTask == nil {
                state.repositionPanel(action: action)
            }
                
            hideTetherWindow()
        } else if !state.panelOpened {
            // Panel closed
            KeyboardShortcutsManager.disable(modelContainer: SwiftDataContainer.appContainer)
            debouncedShowTetherWindow(state: state, activeWindow: window)
        } else {
            // Panel minified
            KeyboardShortcutsManager.disable(modelContainer: SwiftDataContainer.appContainer)
            debouncedShowTetherWindow(state: state, activeWindow: window)
        }
        
        if let trackedWindow = state.trackedWindow {
            updateLevelState(trackedWindow: trackedWindow)
        }
    }
    
    private func saveInitialFrameIfNeeded(for window: AXUIElement, state: OnitPanelState) {
        if targetInitialFrames[window] == nil,
                  let position = window.position(),
                  let size = window.size(),
                  state.currentAnimationTask == nil {
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
        
        tetherWindow.orderFrontRegardless()
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
        
        if Self.isFinder(activeWindow: activeWindow) {
            if Self.isFinderShowingDesktopOnly(activeWindow: activeWindow) {
                if let mouseScreen = NSRect(origin: NSEvent.mouseLocation, size: NSSize(width: 1, height: 1)).findScreen() {
                    let screenFrame = mouseScreen.visibleFrame
               
                    windowFrame = screenFrame
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
        
        var lastYComputed = lastYComputed ?? getCenterPositionY(for: windowFrame) ?? 0
        
        if let distanceFromBottom = windowFrame.calculateWindowDistanceFromBottom() {
            state.tetheredButtonYPosition = distanceFromBottom + windowFrame.height - lastYComputed - ExternalTetheredButton.containerHeight
        }

        // This prevents the hint from going beyond the edge of the current screen
        // This can happen when the window is between two screens. 
        if let activeScreen = NSRect(origin: NSEvent.mouseLocation, size: NSSize(width: 1, height: 1)).findScreen() {
            let maxX = activeScreen.visibleFrame.maxX
            if positionX > maxX - ExternalTetheredButton.containerWidth {
                positionX = maxX - ExternalTetheredButton.containerWidth
            }
            
            let minY = activeScreen.visibleFrame.minY
            if lastYComputed < minY {
                lastYComputed = minY
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
        guard let distanceFromBottom = windowFrame.calculateWindowDistanceFromBottom() else {
            return nil
        }
        return distanceFromBottom + windowFrame.height - ExternalTetheredButton.containerHeight
    }

    private func getMinY(for windowFrame: NSRect) -> CGFloat? {
        return windowFrame.calculateWindowDistanceFromBottom() ?? nil
    }

    private func getCenterPositionY(for windowFrame: NSRect) -> CGFloat? {
        guard let distanceFromBottom = windowFrame.calculateWindowDistanceFromBottom() else {
            return nil
        }
        return distanceFromBottom + (windowFrame.height / 2.0) - (ExternalTetheredButton.containerHeight / 2.0)
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
           let currentWindowPosition = currentWindow.position(),
           let currentWindowSize = currentWindow.size() {
            let currentWindowFrame = NSRect(origin: currentWindowPosition, size: currentWindowSize)
                        
            if let currentWindowScreen = currentWindowFrame.dominantScreen() {
                for (key, value) in states {
                    if let position = key.element.position(), let size = key.element.size() {
                        let frame = NSRect(origin: position, size: size)
                        
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
            } else { /** Can't find current window's screen */ }
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
