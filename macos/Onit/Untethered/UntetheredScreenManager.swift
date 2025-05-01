//
//  UntetheredScreenManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 4/23/25.
//

import AppKit
import Defaults
import SwiftUI

@MainActor
class UntetheredScreenManager: ObservableObject {

    // MARK: - Singleton instance

    static let shared = UntetheredScreenManager()
    
    // Reference to the screen-based panel state manager.
    // private let trackedScreenManager = TrackedScreenManager.shared
    
    @Published var state: OnitPanelState
    @Published var tetherButtonPanelState: OnitPanelState?
    
    
    let trackedScreenManager = TrackedScreenManager()
    var lastScreenFrame = CGRect.zero
    
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    var states: [TrackedScreen: OnitPanelState] = [:]
    var isObserving: Bool = false

    private let defaultState = OnitPanelState(trackedScreen: nil)

    static let minOnitWidth: CGFloat = ContentView.idealWidth
    static let spaceBetweenWindows: CGFloat = -(TetheredButton.width / 2)

    var tetherHintDetails: TetherHintDetails
    var tutorialWindow: NSWindow

    private var shouldShowOnboarding: Bool {
        let accessibilityPermissionGranted = AccessibilityPermissionManager.shared.accessibilityPermissionStatus == .granted
        return !accessibilityPermissionGranted && Defaults[.showOnboarding]
    }

    // Dictionary that tracks whether the ExternalTetherButton should be visible for each screen.
    // (For example, if the panel is closed then the tether button is visible.)
    @Published var tetherButtonVisibility: [NSScreen: Bool] = [:]
    
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
        
        tutorialWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: (TetherTutorialOverlay.width * 1.5), height: (TetherTutorialOverlay.height * 1.5)),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        tutorialWindow.isOpaque = false
        tutorialWindow.backgroundColor = NSColor.clear
        tutorialWindow.level = .floating
        tutorialWindow.hasShadow = false
        tutorialWindow.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        tutorialWindow.isReleasedWhenClosed = false
        tutorialWindow.titlebarAppearsTransparent = true
        tutorialWindow.titleVisibility = .hidden
        tutorialWindow.standardWindowButton(.closeButton)?.isHidden = true
        tutorialWindow.standardWindowButton(.miniaturizeButton)?.isHidden = true
        tutorialWindow.standardWindowButton(.zoomButton)?.isHidden = true
        
        let tutorialView = NSHostingView(rootView: TetherTutorialOverlay())
        tutorialWindow.contentView = tutorialView
        
        tetherHintDetails = TetherHintDetails(tetherWindow: window)
        state = defaultState
    }

    // MARK: - Functions

    func startObserving() {
        guard !isObserving else { return }
        
        isObserving = true
        
        // Add global monitor to capture mouse moved events
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            handleMouseMoved(event: event)
        }

        // Add local monitor to capture mouse moved events when the application is foregrounded
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return event }
            handleMouseMoved(event: event)
            return event
        }
        
        // Add the main screen on startup.
        if let mouseScreen = NSScreen.mouse {
            if let trackedScreen = trackedScreenManager.append(screen: mouseScreen) {
                handleActivation(of: trackedScreen)
            }
            lastScreenFrame = mouseScreen.frame
        }
    }

    func stopObserving() {
        isObserving = false
        if let globalMouseMonitor = globalMouseMonitor {
            NSEvent.removeMonitor(globalMouseMonitor)
            self.globalMouseMonitor = nil
        }
        
        if let localMouseMonitor = localMouseMonitor {
            NSEvent.removeMonitor(localMouseMonitor)
            self.localMouseMonitor = nil
        }
        hideTetherWindow()
    }

    private func handleMouseMoved(event: NSEvent) {
        if let mouseScreen = NSScreen.mouse {
            if !mouseScreen.frame.equalTo(lastScreenFrame) {
                if let trackedScreen = trackedScreenManager.append(screen: mouseScreen) {
                    handleActivation(of: trackedScreen)
                }
                lastScreenFrame = mouseScreen.frame
            }
        }
    }
    
    private func handleActivation(of screen: TrackedScreen) {
        let panelState = getState(for: screen)
        handlePanelStateChange(state: panelState, action: .undefined)
    }
    
    func handlePanelStateChange(state: OnitPanelState, action: TrackedScreenAction) {
        guard let screen = state.trackedScreen else {
            return
        }

        if !state.hidden {
            if state.panelOpened {
                hideTetherWindow()
                if state.currentAnimationTask == nil {
                    state.repositionPanel(action: .undefined)
                }
            } else {
                debouncedShowTetherWindow(state: state, activeScreen: screen, action: action)
            }
        } else {
            // We can't hide the panel in untethered mode.   
        }

        state.panel?.setLevel(.floating)
    }


    func getState(for trackedScreen: TrackedScreen) -> OnitPanelState {
        let panelState: OnitPanelState

        if let (_, activeState) = states.first(where: { (key: TrackedScreen, value: OnitPanelState) in
            key == trackedScreen
        }) {
            activeState.trackedScreen = trackedScreen
            panelState = activeState
        } else {
            panelState = OnitPanelState(trackedScreen: trackedScreen)
            
            states[trackedScreen] = panelState
        }

        panelState.addDelegate(self)
        state = panelState
        return panelState
    }


    func debouncedShowTetherWindow(state: OnitPanelState, activeScreen: TrackedScreen, action: TrackedScreenAction) {
        hideTetherWindow()
        let pendingTetherWindow = (state, activeScreen)

        tetherHintDetails.showTetherDebounceTimer = Timer.scheduledTimer(withTimeInterval: tetherHintDetails.showTetherDebounceDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if self.isObserving {
                    self.showTetherWindow(state: pendingTetherWindow.0, activeScreen: pendingTetherWindow.1.screen, action: action)
                }
            }
        }
    }
    
    func hideTetherWindow() {
        tetherHintDetails.showTetherDebounceTimer = nil
        tetherButtonPanelState = nil

        tetherHintDetails.tetherWindow.orderOut(nil)
        tetherHintDetails.tetherWindow.contentView = nil
        tetherHintDetails.lastYComputed = nil
        
        // Remove the tutorial
        tutorialWindow.orderOut(nil)
        tutorialWindow.contentView = nil
    }

    func showTetherWindow(state: OnitPanelState, activeScreen: NSScreen, action: TrackedScreenAction) {
         let tetherView = ExternalTetheredButton(
             onDrag: { [weak self] translation in
                 self?.tetheredWindowMoved(screen: activeScreen, y: translation)
             }
         ).environment(\.windowState, state)

        let buttonView = NSHostingView(rootView: tetherView)
        tetherHintDetails.tetherWindow.contentView = buttonView
        tetherHintDetails.lastYComputed = nil
        tetherButtonPanelState = state

        if (shouldShowOnboarding) {
            let tutorialView = TetherTutorialOverlay()
            tutorialWindow.contentView = NSHostingView(rootView: tutorialView)
            tutorialWindow.orderFrontRegardless()
        }

        updateTetherWindowPosition(for: activeScreen, action: action, lastYComputed: tetherHintDetails.lastYComputed)
        tetherHintDetails.tetherWindow.orderFrontRegardless()
    }
    
    private func updateTetherWindowPosition(for screen: NSScreen, action: TrackedScreenAction, lastYComputed: CGFloat? = nil) {
        let activeScreenFrame = screen.visibleFrame
        let positionX = activeScreenFrame.maxX - ExternalTetheredButton.containerWidth
        var positionY: CGFloat
        
        if lastYComputed == nil {
            positionY = activeScreenFrame.minY + (activeScreenFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)
        } else {
            positionY = computeHintYPosition(for: activeScreenFrame, offset: lastYComputed)
        }
        
        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        tetherHintDetails.tetherWindow.setFrame(frame, display: false)
        
        if (shouldShowOnboarding) {
            let tutorialFrame = NSRect(
                x: positionX - (TetherTutorialOverlay.width) + (ExternalTetheredButton.containerWidth / 2),
                y: positionY + (ExternalTetheredButton.containerHeight / 2) - ((TetherTutorialOverlay.height * 1.5) / 2),
                width: (TetherTutorialOverlay.width * 1.5),
                height: (TetherTutorialOverlay.height * 1.5)
            )
            tutorialWindow.setFrame(tutorialFrame, display: false)
        }
    }
    
    private func computeHintYPosition(for screenVisibleFrame: CGRect, offset: CGFloat?) -> CGFloat {
        let maxY = screenVisibleFrame.maxY - ExternalTetheredButton.containerHeight
        let minY = screenVisibleFrame.minY

        var lastYComputed = tetherHintDetails.lastYComputed ?? screenVisibleFrame.minY + (screenVisibleFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)

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

    private func tetheredWindowMoved(screen: NSScreen, y: CGFloat) {
        let screenFrame = screen.visibleFrame
        let lastYComputed = computeHintYPosition(for: screenFrame, offset: y)
        
        tetherHintDetails.lastYComputed = lastYComputed
        
        if let state = tetherButtonPanelState {
            state.tetheredButtonYPosition = screenFrame.height -
                (lastYComputed - screenFrame.minY) -
                ExternalTetheredButton.containerHeight + (TetheredButton.height / 2)
        }

        let frame = NSRect(
            x: tetherHintDetails.tetherWindow.frame.origin.x,
            y: lastYComputed,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        
        tetherHintDetails.tetherWindow.setFrame(frame, display: true)
    }
    
}

// MARK: - OnitPanelStateDelegate

extension UntetheredScreenManager: OnitPanelStateDelegate {
    func panelBecomeKey(state: OnitPanelState) {
        self.state = state
        KeyboardShortcutsManager.enable(modelContainer: SwiftDataContainer.appContainer)
    }
    func panelResignKey(state: OnitPanelState) {
        KeyboardShortcutsManager.disable(modelContainer: SwiftDataContainer.appContainer)
    }
    func panelStateDidChange(state: OnitPanelState) {
        handlePanelStateChange(state: state, action: .undefined)
    }
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) { }
}

