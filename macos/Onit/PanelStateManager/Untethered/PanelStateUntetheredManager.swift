//
//  PanelStateUntetheredManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 4/23/25.
//

import AppKit
import Defaults
import PostHog
import SwiftUI

@MainActor
class PanelStateUntetheredManager: PanelStateBaseManager, ObservableObject {

    // MARK: - Singleton instance

    static let shared = PanelStateUntetheredManager()
    
    // MARK: - Properties
    
    var lastScreenFrame = CGRect.zero
    var hintYRelativePositionsByScreen: [String: CGFloat] = [:]
    
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    var statesByScreen: [NSScreen: OnitPanelState] = [:] {
        didSet {
            states = Array(statesByScreen.values)
        }
    }

    var tutorialWindow: NSWindow
    
    // MARK: - Initializer
    
    private override init() {
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
        
        super.init()
    }

    // MARK: - PanelStateManagerLogic

    override func start() {
        stop()
        
        // Add global monitor to capture mouse moved events
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            handleMouseMoved()
        }

        // Add local monitor to capture mouse moved events when the application is foregrounded
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return event }
            handleMouseMoved()
            return event
        }
        
        // Add the main screen on startup.
        if let mouseScreen = NSScreen.mouse {
            handleActivation(of: mouseScreen)
            lastScreenFrame = mouseScreen.frame
        }
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
        
        super.stop()
        
        lastScreenFrame = CGRect.zero
        hintYRelativePositionsByScreen = [:]
        statesByScreen = [:]
    }
    
    override func getState(for windowHash: UInt) -> OnitPanelState? {
        return nil
    }

    override func filterHistoryChats(_ chats: [Chat]) -> [Chat] {
        return super.filterHistoryChats(chats)
    }
    
    override func filterPanelChats(_ chats: [Chat]) -> [Chat] {
        return super.filterPanelChats(chats)
    }
    
    override func launchPanel(for state: OnitPanelState) {
        AnalyticsManager.Panel.opened(displayMode: "untethered")
        
        buildPanelIfNeeded(for: state)
        showPanel(for: state)
    }
    
    override func closePanel(for state: OnitPanelState) {
        AnalyticsManager.Panel.closed(displayMode: "untethered")
        hidePanel(for: state)
        
        super.closePanel(for: state)
    }
    
    // MARK: - PanelStateBaseManager
    
    override func hideTetherWindow() {
        super.hideTetherWindow()
        
        // Remove the tutorial
        tutorialWindow.orderOut(nil)
        tutorialWindow.contentView = nil
    }
    
    // MARK: - Functions

    private func handleMouseMoved() {
        if let mouseScreen = NSScreen.mouse {
            if !mouseScreen.frame.equalTo(lastScreenFrame) {
                handleActivation(of: mouseScreen)
                lastScreenFrame = mouseScreen.frame
            }
        }
    }
    
    private func handleActivation(of screen: NSScreen) {
        let panelState = getState(for: screen)
        handlePanelStateChange(state: panelState)
    }
    
    func handlePanelStateChange(state: OnitPanelState) {
        guard let screen = state.trackedScreen else {
            return
        }

        if !state.hidden {
            if state.panelOpened {
                hideTetherWindow()
                if state.currentAnimationTask == nil {
                    showPanel(for: state)
                }
            } else {
                debouncedShowTetherWindow(state: state, activeScreen: screen)
            }
        } else {
            // We can't hide the panel in untethered mode.   
        }

        state.panel?.setLevel(.floating)
    }


    func getState(for screen: NSScreen) -> OnitPanelState {
        let panelState: OnitPanelState

        if let (_, activeState) = statesByScreen.first(where: { (key: NSScreen, value: OnitPanelState) in
            key == screen
        }) {
            activeState.trackedScreen = screen
            panelState = activeState
        } else {
            panelState = OnitPanelState(screen: screen)
            
            statesByScreen[screen] = panelState
        }

        panelState.addDelegate(self)
        state = panelState
        return panelState
    }
}

// MARK: - OnitPanelStateDelegate

extension PanelStateUntetheredManager: OnitPanelStateDelegate {
    func panelBecomeKey(state: OnitPanelState) {
        self.state = state
        KeyboardShortcutsManager.enable(modelContainer: SwiftDataContainer.appContainer)
    }
    func panelResignKey(state: OnitPanelState) {
        KeyboardShortcutsManager.disable(modelContainer: SwiftDataContainer.appContainer)
    }
    func panelStateDidChange(state: OnitPanelState) {
        handlePanelStateChange(state: state)
    }
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) { }
}

