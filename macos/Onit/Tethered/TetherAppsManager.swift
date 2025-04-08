//
//  TetherAppsManager.swift
//  Onit
//
//  Created by Kévin Naudin on 12/03/2025.
//

import AppKit
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
    private var dragDebounce: AnyCancellable?
    
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
            .sink { [weak self] isRegularApp in
                guard let self = self else { return }
                
                if isRegularApp {
                    self.startAllObservers()
                } else {
                    self.stopAllObservers()
                    self.resetFramesOnAppChange()
                }
                
                if self.skipFirstRegularAppUpdate {
                    self.skipFirstRegularAppUpdate = false
                } else {
                    self.setAppAsRegular(isRegularApp)
                }
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
    
    // MARK: - Handling panel state changes
    
    private func handlePanelStateChange(state: OnitPanelState, isOpened: Bool, isMiniaturized: Bool) {
        guard let window = state.trackedWindow?.element else {
            return
        }
        
        if isOpened && !isMiniaturized {
            // Panel opened
            saveInitialFrameIfNeeded(for: window)
            hideTetherWindow()

            state.repositionPanel()
            
            if let trackedWindow = state.trackedWindow {
                updateLevelState(trackedWindow: trackedWindow)
            }
        } else if !isOpened {
            // Panel closed
            showTetherWindow(state: state, activeWindow: window)
        } else {
            // Panel minified
            showTetherWindow(state: state, activeWindow: window)
        }
    }
    
    private func saveInitialFrameIfNeeded(for window: AXUIElement) {
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
    
    func showTetherWindow(state: OnitPanelState, activeWindow: AXUIElement?) {
        let tetherView = ExternalTetheredButton(
            onDrag: { [weak self] translation in
                self?.tetheredWindowMoved(y: translation)
            }
        ).environment(\.windowState, state)
        
        let buttonView = NSHostingView(rootView: tetherView)
        tetherWindow.contentView = buttonView
        lastYComputed = nil
        
        if isFinderShowingDesktopOnly(activeWindow: activeWindow) {
            if let mouseScreen = NSRect(origin: NSEvent.mouseLocation, size: NSSize(width: 1, height: 1)).findScreen() {
                let screenFrame = mouseScreen.frame
                
                let frame = NSRect(
                    x: screenFrame.maxX - ExternalTetheredButton.containerWidth,
                    y: screenFrame.maxY - ExternalTetheredButton.containerHeight,
                    width: ExternalTetheredButton.containerWidth,
                    height: ExternalTetheredButton.containerHeight
                )
                tetherWindow.setFrame(frame, display: true)
            }
        } else {
            updateTetherWindowPosition(for: activeWindow)
        }
        
        tetherWindow.orderFront(nil)
    }
    
    private func hideTetherWindow() {
        tetherWindow.orderOut(nil)
        tetherWindow.contentView = nil
        lastYComputed = nil
    }
    
    func updateTetherWindowPosition(for window: AXUIElement?) {
        guard let activeWindow = window,
              let size = activeWindow.size(),
              let position = activeWindow.position() else {
            return
        }
        
        if lastYComputed == nil {
            lastYComputed = getCenterPositionY(for:activeWindow) ?? 0 // Will this ever fail?
        } else {
            lastYComputed = computeTetheredWindowY(activeWindow: activeWindow, offset: nil)
        }
        guard let lastYComputed = lastYComputed else { return }
        
        let frame = NSRect(
            x: position.x + size.width - ExternalTetheredButton.containerWidth,
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
        
        self.lastYComputed = computeTetheredWindowY(activeWindow: trackedWindow.element, offset: y)
        self.updateTetherWindowPosition(for: trackedWindow.element)
    }
    
    private func computeTetheredWindowY(activeWindow: AXUIElement, offset: CGFloat?) -> CGFloat? {
        guard let windowFrame = activeWindow.frame(),
              let maxY = getMaxY(for: activeWindow),
              let minY = getMinY(for: activeWindow) else { return nil }
        
        var lastYComputed = self.lastYComputed ?? (getCenterPositionY(for: activeWindow) ?? 0)
        
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
      
    private func getMaxY(for activeWindow: AXUIElement) -> CGFloat? {
        guard let distanceFromBottom = calculateWindowDistanceFromBottom(for: activeWindow),
              let windowFrame = activeWindow.frame() else {
            return nil
        }
        return distanceFromBottom + windowFrame.height - ExternalTetheredButton.containerHeight
    }

    private func getMinY(for activeWindow: AXUIElement) -> CGFloat? {
        return calculateWindowDistanceFromBottom(for: activeWindow) ?? nil
    }

    private func getCenterPositionY(for activeWindow: AXUIElement) -> CGFloat? {
        guard let distanceFromBottom = calculateWindowDistanceFromBottom(for: activeWindow),
              let windowFrame = activeWindow.frame() else {
            return nil
        }
        return distanceFromBottom + (windowFrame.height / 2.0) - (ExternalTetheredButton.containerHeight / 2.0)
    }
    
    private func calculateWindowDistanceFromBottom(for activeWindow: AXUIElement) -> CGFloat? {
        guard let windowFrame = activeWindow.frame(),
              let activeScreen = windowFrame.findScreen() else { return nil }
        
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

    
    private func isFinderShowingDesktopOnly(activeWindow: AXUIElement?) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        
        guard let finderAppPid = runningApps.first(where: { $0.bundleIdentifier == "com.apple.finder" })?.processIdentifier,
              let activeWindow = activeWindow,
              activeWindow.pid() == finderAppPid else {
            
            return false
        }
        
        return activeWindow.getWindows().first?.role() == "AXScrollArea"
    }
    
    func updateLevelState(trackedWindow: TrackedWindow?) {
        if let trackedWindow = trackedWindow {
            for (key, value) in states {
                if key == trackedWindow {
                    value.panel?.level = .floating
                } else if value.panel?.level == .floating {
                    value.panel?.level = .normal
                    value.panel?.orderBack(nil)
                }
            }
        }
    }
    
    private func setAppAsRegular(_ value: Bool) {
        closeAllPanels()
        
        if value {
            state.launchPanel()
        } else {
            state = defaultState
            state.launchPanel()
        }
    }
    
    private func closeAllPanels() {
        defaultState.closePanel()
        
        for (_, state) in states {
            state.closePanel()
        }
    }
}

// MARK: - AccessibilityNotificationsDelegate

extension TetherAppsManager: AccessibilityNotificationsDelegate {
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        let panelState: OnitPanelState
        
        if let (key, activeState) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
            key == window
        }) {
            panelState = activeState
        } else {
            panelState = OnitPanelState(trackedWindow: window)
            
            states[window] = panelState
        }
        
        panelState.addDelegate(self)
        state = panelState
        handlePanelStateChange(state: panelState, isOpened: panelState.isOpened, isMiniaturized: panelState.isMiniaturized)
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {
        if let (key, state) = states.first(where: { (key: TrackedWindow, value: OnitPanelState) in
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
    
    func panelStateDidChange(state: OnitPanelState, isOpened: Bool, isMiniaturized: Bool) {
        handlePanelStateChange(state: state, isOpened: isOpened, isMiniaturized: isMiniaturized)
    }
}
