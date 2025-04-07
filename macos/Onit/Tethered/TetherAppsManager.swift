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
    
    private var regularAppCancellable: AnyCancellable?
    private var otherCancellables = Set<AnyCancellable>()
    
    private let minOnitWidth: CGFloat = ContentView.idealWidth
    private let spaceBetweenWindows: CGFloat = -(TetheredButton.width / 2)
    
    var targetInitialFrames: [AXUIElement: CGRect] = [:]
    
    private let tetherWindow: NSWindow
    private var lastYComputed: CGFloat?
    private var dragDebounce: AnyCancellable?
    
    struct ActiveWindowState {
        let state: OnitPanelState
        let isPanelOpened: Bool
        let isPanelMiniaturized: Bool
        
        var isPanelOpenedAndNotMinimized: Bool {
            isPanelOpened && !isPanelMiniaturized
        }
    }
    
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
    }
    
    // MARK: - Functions
    
    func startObserving() {
        stopObserving()

        let isRegularAppPublisher = Defaults.publisher(.isRegularApp)
            .map(\.newValue)
        
        regularAppCancellable = isRegularAppPublisher
            .sink { [weak self] isRegularApp in
                if isRegularApp {
                    self?.startAllObservers()
                } else {
                    self?.targetInitialFrames.forEach { element, initialFrame in
                        guard let self = self,
                              let window = element.findWindow(),
                              let position = window.position(),
                              let size = window.size() else {
                            return
                        }
                        
                        let fromActive = NSRect(origin: position, size: size)
                        
                        self.animateExit(windowState: nil, activeWindow: window, fromActive: fromActive, toActive: initialFrame)
                    }
                    self?.targetInitialFrames.removeAll()
                    self?.stopAllObservers()
                }
            }
    }
    
    func stopObserving() {
        regularAppCancellable?.cancel()
        regularAppCancellable = nil
        stopAllObservers()
    }
    
    // MARK: - Private functions
    
    private func startAllObservers() {
        OnitPanelManager.shared.$state
            .flatMap { state in
                return Publishers.CombineLatest(state.isPanelOpened, state.isPanelMiniaturized)
                    .map {
                        ActiveWindowState(
                            state: state,
                            isPanelOpened: $0,
                            isPanelMiniaturized: $1
                        )
                    }
            }
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .sink(receiveValue: windowPositioningObserver)
            .store(in: &otherCancellables)
        
        AccessibilityNotificationsManager.shared.$destroyedTrackedWindow
            .sink(receiveValue: windowDestroyedObserver)
            .store(in: &otherCancellables)
    }
    
    private func stopAllObservers() {
        otherCancellables.removeAll()
        hideTetherWindow()
    }
    
    // MARK: - Observers
    private func windowDestroyedObserver(trackedWindow: TrackedWindow?) {
        guard let trackedWindow = trackedWindow else { return }
        
        print("TetherAppsManager - Destroyed window from : \(trackedWindow)")
        
        hideTetherWindow()
    }
    
    private func windowPositioningObserver(windowState: ActiveWindowState) {
        //print("TetherAppsManager - windowPositioningObserver pid:\(windowState.state.trackedWindow?.pid ?? -1) isOpen:\(windowState.isPanelOpened) isMinimized:\(windowState.isPanelMiniaturized)")
        guard let window = windowState.state.trackedWindow?.element, let windowPid = windowState.state.trackedWindow?.pid else {
            return
        }
        
        if windowState.isPanelOpenedAndNotMinimized {
            panelOpened(windowState: windowState, window: window, windowPid: windowPid)
        } else if !windowState.isPanelOpened {
            panelClosed(windowState: windowState, window: window, windowPid: windowPid)
        } else {
            panelMinimized(windowState: windowState, window: window, windowPid: windowPid)
        }
    }
    
    private func panelOpened(windowState: ActiveWindowState, window: AXUIElement, windowPid: pid_t) {
        print("TetherAppsManager panelOpened \(CFHash(window))")
        hideTetherWindow()
        
        if targetInitialFrames[window] == nil, let position = window.position(), let size = window.size() {
            targetInitialFrames[window] = CGRect(x: position.x,
                                                    y: position.y,
                                                    width: size.width,
                                                    height: size.height)
        }
        
        repositionWindow(window: window, state: windowState.state)
        // TODO: KNA - Tethered
        //OnitPanelManager.shared.updateLevelState(elementIdentifier: AXUIElementIdentifier(window: window, pid: windowPid))
    }
    
    private func panelClosed(windowState: ActiveWindowState, window: AXUIElement, windowPid: pid_t) {
        print("TetherAppsManager panelClosed \(CFHash(window))")
        if let initialFrame = targetInitialFrames[window] {
            if let panel = windowState.state.panel, let position = window.position(), let size = window.size() {
                let fromActive = NSRect(origin: position, size: size)
                let toPanelX = initialFrame.minX + initialFrame.maxX - (panel.frame.width / 2)
                let fromPanel = panel.frame
                let toPanel = NSRect(origin: NSPoint(x: toPanelX, y: panel.frame.minY), size: panel.frame.size)
                
                self.animateExit(windowState: windowState, activeWindow: window, fromActive: fromActive, toActive: initialFrame,
                                 panel: panel, fromPanel: fromPanel, toPanel: toPanel)
            }
        } else {
            showTetherWindow(windowState: windowState, activeWindow: window)
            //windowState.state.panel?.hide()
        }
    }
    
    private func panelMinimized(windowState: ActiveWindowState, window: AXUIElement, windowPid: pid_t) {
        if let initialFrame = targetInitialFrames[window] {
            if let position = window.position(), let size = window.size() {
                let fromActive = NSRect(origin: position, size: size)
                
                self.animateExit(windowState: nil, activeWindow: window, fromActive: fromActive, toActive: initialFrame)
            } else {
                _ = window.setFrame(initialFrame)
            }
            
            targetInitialFrames.removeValue(forKey: window)
        }
        
        showTetherWindow(windowState: windowState, activeWindow: window)
    }
    
    private func repositionWindow(window: AXUIElement, state: OnitPanelState) {
        guard let panel = state.panel,
              let position = window.position(),
              let size = window.size() else {
            return
        }
        //print("repositionWindow position:\(position), size:\(size)")
        
        // Special case for Finder (desktop)
        if isFinderShowingDesktopOnly(activeWindow: window) {
            if let mouseScreen = NSRect(origin: NSEvent.mouseLocation, size: NSSize(width: 1, height: 1)).findScreen() {
                let screenFrame = mouseScreen.frame
                let onitWidth = minOnitWidth
                let onitHeight = screenFrame.height - ContentView.bottomPadding
                let onitY = screenFrame.maxY - onitHeight
                let onitX = screenFrame.maxX - onitWidth
                
                panel.setFrame(NSRect(
                    x: onitX,
                    y: onitY,
                    width: onitWidth,
                    height: onitHeight
                ), display: true, animate: true)
            }
            return
        }
        
        guard let screen = NSRect(origin: position, size: size).findScreen() else { return }
        
        let screenFrame = screen.frame
        let onitWidth = minOnitWidth
        let onitHeight = min(size.height, screenFrame.height - ContentView.bottomPadding)
        let onitY = screenFrame.maxY - (position.y + onitHeight)
        
        let spaceOnRight = screenFrame.maxX - (position.x + size.width)
        let hasEnoughSpace = spaceOnRight >= onitWidth + spaceBetweenWindows
        
        if hasEnoughSpace {
            let toPanel = NSRect(
                x: position.x + size.width + spaceBetweenWindows,
                y: onitY,
                width: onitWidth,
                height: onitHeight
            )
            
            animateEnter(activeWindow: window,
                         fromActive: nil,
                         toActive: nil,
                         panel: panel,
                         fromPanel: toPanel,
                         toPanel: toPanel
            )
        } else {
            let maxActiveAppWidth = screenFrame.width - onitWidth - spaceBetweenWindows
            let activeAppWidth = min(size.width, maxActiveAppWidth)
            
            let activeWindowSourceRect = CGRect(
                x: position.x,
                y: position.y,
                width: size.width,
                height: size.height
            )
            let activeWindowTargetRect = CGRect(
                x: position.x,
                y: position.y,
                width: activeAppWidth,
                height: size.height
            )
            let panelSourceRect: CGRect = panel.frame
            let panelTargetRect = NSRect(
                x: position.x + activeAppWidth + spaceBetweenWindows,
                y: onitY,
                width: onitWidth,
                height: onitHeight
            )

            animateEnter(
                activeWindow: window,
                fromActive: activeWindowSourceRect,
                toActive: activeWindowTargetRect,
                panel: panel,
                fromPanel: panelSourceRect,
                toPanel: panelTargetRect
            )
        }
    }

    func showTetherWindow(windowState: ActiveWindowState, activeWindow: AXUIElement?) {
        let tetherView = ExternalTetheredButton(
            onDrag: { [weak self] translation in
                self?.tetheredWindowMoved(y: translation)
            }
        ).environment(\.windowState, windowState.state)
        
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
}
