//
//  HintManager+Panel.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Public Functions: Show Hint
 * Private Functions: Tethered Mode
 * Private Functions: Pinned Mode
 * Private Functions: Untethered Mode
 * Private Functions: Helper Functions
 */

@preconcurrency import AppKit
import Defaults
import SwiftUI

extension HintManager {
    // MARK: - Public Functions: Show Hint
    
    /// Show hint for tethered mode (attached to a window).
    func showHintForTethered(
        state: OnitPanelState,
        activeWindow: AXUIElement,
        action: TrackedWindowAction,
        onClick: @escaping () -> Void
    ) {
        guard shouldShowHint else { return }

        /// If hint is already visible, reposition immediately (skip debounce).
        if hintWindowIsVisible {
            if currentPanelState !== state {
                currentPanelState = state
            }

            showHintImmediately(
                for: .tethered,
                panelState: state,
                activeWindow: activeWindow,
                trackedWindowAction: action,
                onSidebarClick: onClick
            )
            return
        }

        nonisolated(unsafe) let sendableOnClick = onClick
        showDebounceTimer = Timer.scheduledTimer(
            withTimeInterval: showDebounceDelay,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.showHintImmediately(
                    for: .tethered,
                    panelState: state,
                    activeWindow: activeWindow,
                    trackedWindowAction: action,
                    onSidebarClick: sendableOnClick
                )
            }
        }
    }

    /// Show hint for pinned mode (attached to a screen).
    func showHintForPinned(
        state: OnitPanelState,
        activeScreen: NSScreen,
        onClick: @escaping () -> Void
    ) {
        guard shouldShowHint else { return }

        /// If hint is already visible, reposition immediately (skip debounce).
        if hintWindowIsVisible {
            if currentPanelState !== state {
                currentPanelState = state
            }
            lastYComputed = nil
            showHintImmediately(
                for: .pinned,
                panelState: state,
                activeScreen: activeScreen,
                onSidebarClick: onClick
            )
            return
        }

        nonisolated(unsafe) let sendableOnClick = onClick
        showDebounceTimer = Timer.scheduledTimer(
            withTimeInterval: showDebounceDelay,
            repeats: false
        ) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.showHintImmediately(
                    for: .pinned,
                    panelState: state,
                    activeScreen: activeScreen,
                    onSidebarClick: sendableOnClick
                )
            }
        }
    }

    /// Show hint for untethered mode (attached to a screen, no accessibility).
    func showHintForUntethered(
        state: OnitPanelState,
        activeScreen: NSScreen,
        onClick: @escaping () -> Void
    ) {
        guard shouldShowHint else { return }

        /// If hint is already visible, reposition immediately (skip debounce).
        if hintWindowIsVisible {
            if currentPanelState !== state {
                currentPanelState = state
            }
            lastYComputed = nil
            showHintImmediately(
                for: .untethered,
                panelState: state,
                activeScreen: activeScreen,
                onSidebarClick: onClick
            )
            return
        }

        nonisolated(unsafe) let sendableOnClick = onClick
        showDebounceTimer = Timer.scheduledTimer(withTimeInterval: showDebounceDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.showHintImmediately(
                    for: .untethered,
                    panelState: state,
                    activeScreen: activeScreen,
                    onSidebarClick: sendableOnClick
                )
            }
        }
    }
    
    // MARK: - Private Functions: Tethered Mode

    private func updateTetheredPosition(for window: AXUIElement?, action: TrackedWindowAction, lastYComputed: CGFloat? = nil) {
        guard let activeWindow = window,
              let activeWindowFrame = activeWindow.getFrame(convertedToGlobalCoordinateSpace: true) else {
            return
        }

        var positionX = activeWindowFrame.origin.x + activeWindowFrame.width - currentHintSize.width
        var optionalWindowFrame: CGRect?

        if activeWindow.isFinder {
            if activeWindow.isDesktopFinder {
                if let mouseScreen = NSScreen.mouse {
                    let screenFrame = mouseScreen.visibleFrame
                    optionalWindowFrame = screenFrame
                    positionX = screenFrame.maxX - currentHintSize.width
                }
            } else {
                /// This block represents a click on the desktop.
                /// Removing tethered hint window becauase the desktop is not an app window.
                if let isMain = activeWindow.isMain(), let isMinimized = activeWindow.isMinimized() {
                    if !isMain || isMinimized {
                        hideHint()
                        return
                    }
                }
            }
        }

        let windowFrame = optionalWindowFrame ?? activeWindowFrame

        var positionY: CGFloat

        if let appKey = appKey(for: activeWindow),
           let relativePosition = Defaults[.hintYPositionByApp][appKey] {
            positionY = windowFrame.minY + (relativePosition * windowFrame.height) - (currentHintSize.height / 2)
            positionY = max(windowFrame.minY, min(positionY, windowFrame.maxY - currentHintSize.height))
        } else {
            positionY = windowFrame.minY + (windowFrame.height / 2) - (currentHintSize.height / 2)
        }

        let activeScreen = action == .move ? NSScreen.mouse : windowFrame.findScreen()
        if let activeScreen = activeScreen {
            let maxX = activeScreen.visibleFrame.maxX

            if positionX > maxX - currentHintSize.width {
                positionX = maxX - currentHintSize.width
            }

            let minY = activeScreen.visibleFrame.minY
            if positionY < minY {
                positionY = minY
            }
        }

        if let state = currentPanelState,
           let appKey = appKey(for: activeWindow),
           let relativePosition = Defaults[.hintYPositionByApp][appKey] {
            state.tetheredButtonYRelativePosition = relativePosition
        }

        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: currentHintSize.width,
            height: currentHintSize.height
        )

        hintWindow.setFrame(frame, display: false)
    }

    private func handleTetheredDrag(y: CGFloat, state: OnitPanelState) {
        guard let trackedWindow = state.foregroundWindow,
              var windowFrame = trackedWindow.element.getFrame(convertedToGlobalCoordinateSpace: true) else {
            return
        }

        if trackedWindow.element.isDesktopFinder {
            windowFrame = windowFrame.findScreen()?.visibleFrame ?? windowFrame
        }
        
        let computedY = computeClampedY(for: windowFrame, offset: y)
        lastYComputed = computedY

        if let appKey = appKey(for: trackedWindow.element) {
            let relativeY = (computedY + (currentHintSize.height / 2) - windowFrame.minY) / windowFrame.height
            Defaults[.hintYPositionByApp][appKey] = max(0.0, min(1.0, relativeY))
        }

        if let appKey = appKey(for: trackedWindow.element),
           let relativePosition = Defaults[.hintYPositionByApp][appKey] {
            state.tetheredButtonYRelativePosition = relativePosition
        }

        let frame = NSRect(
            x: hintWindow.frame.origin.x,
            y: computedY,
            width: hintWindow.frame.size.width,
            height: hintWindow.frame.size.height
        )

        hintWindow.setFrame(frame, display: true)
        repositionMoreMenuIfNeeded()
    }

    private func appKey(for window: AXUIElement) -> String? {
        let appNamesByWindow = ["Safari", "Google Chrome", "Arc", "Brave Browser", "Opera", "Vivaldi"]
        guard let appName = window.appName() else { return nil }

        if appNamesByWindow.contains(appName) {
            return "\(CFHash(window))"
        }

        return appName
    }
    
    // MARK: - Private Functions: Pinned Mode

    private func handlePinnedDrag(screen: NSScreen, y: CGFloat, state: OnitPanelState) {
        let screenFrame = screen.visibleFrame
        let computedY = computeClampedY(for: screenFrame, offset: y)
        
        lastYComputed = computedY

        let relativeY = (computedY + (currentHintSize.height / 2) - screenFrame.minY) / screenFrame.height

        Defaults[.hintYPositionForPinnedMode] = max(0.0, min(1.0, relativeY))
        Defaults[.hintYPositionForUntetheredModeScreens][screenKey(for: screen)] = max(0.0, min(1.0, relativeY))
        currentPanelState?.tetheredButtonYRelativePosition = Defaults[.hintYPositionForPinnedMode]

        let frame = NSRect(
            x: hintWindow.frame.origin.x,
            y: computedY,
            width: hintWindow.frame.size.width,
            height: hintWindow.frame.size.height
        )

        hintWindow.setFrame(frame, display: true)
        repositionMoreMenuIfNeeded()
    }

    private func updatePinnedPosition(
        for screen: NSScreen,
        lastYComputed: CGFloat? = nil
    ) {
        let activeScreenFrame = screen.visibleFrame
        let positionX = activeScreenFrame.maxX - currentHintSize.width
        var positionY: CGFloat

        if let relativePosition = Defaults[.hintYPositionForPinnedMode] {
            positionY = activeScreenFrame.minY + (relativePosition * activeScreenFrame.height) - (currentHintSize.height / 2)
            positionY = max(activeScreenFrame.minY, min(positionY, activeScreenFrame.maxY - currentHintSize.height))
        } else if lastYComputed == nil {
            positionY = activeScreenFrame.minY + (activeScreenFrame.height / 2) - (currentHintSize.height / 2)
        } else {
            positionY = computeClampedY(for: activeScreenFrame, offset: lastYComputed)
        }

        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: currentHintSize.width,
            height: currentHintSize.height
        )
        hintWindow.setFrame(frame, display: false)
    }
    
    // MARK: - Private Functions: Untethered Mode

    private func updateUntetheredPosition(for screen: NSScreen, state: OnitPanelState, lastYComputed: CGFloat? = nil) {
        let activeScreenFrame = screen.visibleFrame
        let positionX = activeScreenFrame.maxX - currentHintSize.width
        var positionY: CGFloat
        let screenKey = screenKey(for: screen)

        if let relativePosition = Defaults[.hintYPositionForUntetheredModeScreens][screenKey] {
            positionY = activeScreenFrame.minY + (relativePosition * activeScreenFrame.height) - (currentHintSize.height / 2)
            positionY = max(activeScreenFrame.minY, min(positionY, activeScreenFrame.maxY - currentHintSize.height))

            state.tetheredButtonYRelativePosition = relativePosition
        } else {
            positionY = activeScreenFrame.minY + (activeScreenFrame.height / 2) - (currentHintSize.height / 2)
        }

        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: currentHintSize.width,
            height: currentHintSize.height
        )
        hintWindow.setFrame(frame, display: false)
    }

    private func handleUntetheredDrag(screen: NSScreen, y: CGFloat, state: OnitPanelState) {
        let screenFrame = screen.visibleFrame
        let computedY = computeClampedY(for: screenFrame, offset: y)
        

        lastYComputed = computedY

        let relativeY = (computedY + (currentHintSize.height / 2) - screenFrame.minY) / screenFrame.height
        let screenKey = screenKey(for: screen)

        Defaults[.hintYPositionForUntetheredModeScreens][screenKey] = max(0.0, min(1.0, relativeY))
        Defaults[.hintYPositionForPinnedMode] = max(0.0, min(1.0, relativeY))
        state.tetheredButtonYRelativePosition = Defaults[.hintYPositionForUntetheredModeScreens][screenKey]

        let frame = NSRect(
            x: hintWindow.frame.origin.x,
            y: computedY,
            width: hintWindow.frame.size.width,
            height: hintWindow.frame.size.height
        )

        hintWindow.setFrame(frame, display: true)
        repositionMoreMenuIfNeeded()
    }

    // MARK: - Private Functions: Helper Functions
    
    private func showHintImmediately(
        for hintMode: HintMode,
        panelState: OnitPanelState,
        activeWindow: AXUIElement? = nil,
        trackedWindowAction: TrackedWindowAction? = nil,
        activeScreen: NSScreen? = nil,
        onSidebarClick: @escaping () -> Void
    ) {
        let hintSwiftUIView = generateHintSwiftUIView(
            for: hintMode,
            panelState: panelState,
            activeScreen: activeScreen,
            onSidebarClick: onSidebarClick
        )
        
        let hostingView = OnitHostingView(rootView: hintSwiftUIView)
        hintWindow.contentView = hostingView
        configureFrameChangeObserver(for: hostingView)
        updateHintSize()
        currentPanelState = panelState
        
        updateYPosition(
            for: hintMode,
            panelState: panelState,
            activeWindow: activeWindow,
            trackedWindowAction: trackedWindowAction,
            activeScreen: activeScreen
        )
        
        updateCurrentScreen(
            for: hintMode,
            activeWindow: activeWindow,
            activeScreen: activeScreen
        )
        
        repositionHintToRightEdge()
        hintWindow.orderFrontRegardless()
        startHoverTracking()
    }
    
    private func generateHintSwiftUIView(
        for hintMode: HintMode,
        panelState: OnitPanelState,
        activeScreen: NSScreen? = nil,
        onSidebarClick: @escaping () -> Void
    ) -> some View {
        return Hint(
            onSidebarClick: onSidebarClick,
            onDrag: { [weak self] translation in
                guard let self = self else { return }
                switch hintMode {
                case .tethered:
                    self.handleTetheredDrag(
                        y: translation,
                        state: panelState
                    )
                case .pinned:
                    if let activeScreen = activeScreen {
                        self.handlePinnedDrag(
                            screen: activeScreen,
                            y: translation,
                            state: panelState
                        )
                    } else {
                        break
                    }
                case .untethered:
                    if let activeScreen = activeScreen {
                        self.handleUntetheredDrag(
                            screen: activeScreen,
                            y: translation,
                            state: panelState
                        )
                    } else {
                        break
                    }
                }
            }
        ).environment(\.windowState, panelState)
    }
    
    private func updateYPosition(
        for hintMode: HintMode,
        panelState: OnitPanelState,
        activeWindow: AXUIElement? = nil,
        trackedWindowAction: TrackedWindowAction? = nil,
        activeScreen: NSScreen? = nil
    ) {
        switch hintMode {
        case .tethered:
            if let activeWindow = activeWindow,
               let trackedWindowAction = trackedWindowAction
            {
                updateTetheredPosition(
                    for: activeWindow,
                    action: trackedWindowAction,
                    lastYComputed: lastYComputed
                )
            } else {
                break
            }
        case .pinned:
            if let activeScreen = activeScreen {
                updatePinnedPosition(
                    for: activeScreen,
                    lastYComputed: lastYComputed
                )
            } else {
                break
            }
        case .untethered:
            if let activeScreen = activeScreen {
                updateUntetheredPosition(
                    for: activeScreen,
                    state: panelState,
                    lastYComputed: lastYComputed
                )
            } else {
                break
            }
        }
    }
    
    private func updateCurrentScreen(
        for hintMode: HintMode,
        activeWindow: AXUIElement? = nil,
        activeScreen: NSScreen? = nil
    ) {
        if hintMode == .tethered {
            if let windowFrame = activeWindow?.getFrame(
                convertedToGlobalCoordinateSpace: true
            ) {
                currentScreen = windowFrame.findScreen()
            }
        } else {
            currentScreen = activeScreen
        }
    }
    
    /// In tethered mode, `containerFrame` refers to the frame of the current app window the hint is rendered in.
    /// In pinned and untethered modes, `containerFrame` refers to the frame of the current screen/monitor the user's mouse is in.
    private func computeClampedY(
        for containerFrame: CGRect,
        offset: CGFloat?
    ) -> CGFloat {
        let maxY = containerFrame.maxY - currentHintSize.height
        let minY = containerFrame.minY + 10
        
        var computed = lastYComputed ?? containerFrame.minY + (containerFrame.height / 2) - (currentHintSize.height / 2)
        
        if let offset = offset {
            computed -= offset
        }
        
        if computed > maxY {
            return maxY
        } else if computed < minY {
            return minY
        } else {
            return computed
        }
    }

    private func screenKey(for screen: NSScreen) -> String {
        return "\(screen.frame.origin.x)-\(screen.frame.origin.y)-\(screen.frame.width)-\(screen.frame.height)"
    }
}
