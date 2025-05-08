//
//  PanelStatePinnedManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 07/05/25.
//

import AppKit
import Defaults
import SwiftUI

@MainActor
class PanelStatePinnedManager: PanelStateBaseManager, ObservableObject {

    static let shared = PanelStatePinnedManager()
    
    var statesByScreen: [NSScreen: OnitPanelState] = [:] {
        didSet {
            states = Array(statesByScreen.values)
        }
    }
    
    var tutorialWindow: NSWindow
    
    @Published var tetherButtonVisibility: [NSScreen: Bool] = [:]
    
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


    override func start() {
        stop()

        AccessibilityNotificationsManager.shared.addDelegate(self)
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

    override func stop() {
        AccessibilityNotificationsManager.shared.removeDelegate(self)
        NotificationCenter.default.removeObserver(self)
        
        super.stop()
    }

    @objc private func appDidBecomeActive(_ notification: Notification) { }

    @objc private func applicationWillTerminate() { }
    
    func handlePanelStateChange(state: OnitPanelState) {
        guard let screen = state.trackedScreen else {
            return
        }

        if !state.hidden {
            if state.panelOpened {
                hideTetherWindow()
                showPanelForScreen(state: state, screen: screen)
            } else {
                debouncedShowTetherWindow(state: state, activeScreen: screen)
            }
        } else {
            
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
    
    func showPanelForScreen(state: OnitPanelState, screen: NSScreen) {
        guard let panel = state.panel else { return }
        
        let screenFrame = screen.visibleFrame
        let onitWidth = ContentView.idealWidth
        let onitHeight = screenFrame.height
        
        let newFrame = NSRect(
            x: screenFrame.maxX - onitWidth,
            y: screenFrame.minY,
            width: onitWidth,
            height: onitHeight
        )
        
        if panel.wasAnimated {
            panel.setFrame(newFrame, display: true)
            state.showChatView = true // Add this line to explicitly set showChatView
        } else {
            guard !panel.isAnimating, panel.frame != newFrame else { return }
            
            let fromPanel = NSRect(
                x: screenFrame.maxX - 2,
                y: screenFrame.minY,
                width: 0,
                height: screenFrame.height
            )
            panel.isAnimating = true
            panel.setFrame(fromPanel, display: false)
            panel.alphaValue = 1
            
            state.animateChatView = true
            state.showChatView = false
            
            panel.setFrame(newFrame, display: true)
            state.animateChatView = true
            state.showChatView = true
            panel.isAnimating = false
            panel.wasAnimated = true
        }
        
        resizeOverlappingWindowsIfNeeded(panelFrame: newFrame)
    }
    
    private func resizeOverlappingWindowsIfNeeded(panelFrame: NSRect) {
        let accessibilityManager = AccessibilityNotificationsManager.shared
        let allWindows = accessibilityManager.windowsManager.getAllTrackedWindows()
        
        for window in allWindows {
            guard let windowFrame = window.element.getFrame(convertedToGlobalCoordinateSpace: true) else { continue }
            
            if windowFrame.intersects(panelFrame) {
                let maxWidth = panelFrame.minX - windowFrame.minX - PanelStateBaseManager.spaceBetweenWindows
                
                let newFrame = NSRect(
                    x: windowFrame.minX,
                    y: windowFrame.minY,
                    width: min(maxWidth, windowFrame.width),
                    height: windowFrame.height
                )
                
                _ = window.element.setFrame(newFrame)
            }
        }
    }

    func debouncedShowTetherWindow(state: OnitPanelState, activeScreen: NSScreen) {
        hideTetherWindow()
        let pendingTetherWindow = (state, activeScreen)

        tetherHintDetails.showTetherDebounceTimer?.invalidate()
        tetherHintDetails.showTetherDebounceTimer = Timer.scheduledTimer(withTimeInterval: tetherHintDetails.showTetherDebounceDelay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.showTetherWindow(state: pendingTetherWindow.0, activeScreen: pendingTetherWindow.1)
            }
        }
    }
    
    override func hideTetherWindow() {
        super.hideTetherWindow()
        
        tutorialWindow.orderOut(nil)
        tutorialWindow.contentView = nil
    }

    func showTetherWindow(state: OnitPanelState, activeScreen: NSScreen) {
         let tetherView = ExternalTetheredButton(
             onDrag: { [weak self] translation in
                 self?.tetheredWindowMoved(y: translation)
             }
         ).environment(\.windowState, state)

        let buttonView = NSHostingView(rootView: tetherView)
        tetherHintDetails.tetherWindow.contentView = buttonView
        tetherHintDetails.lastYComputed = nil
        tetherButtonPanelState = state

        updateTetherWindowPosition(for: activeScreen, lastYComputed: tetherHintDetails.lastYComputed)
        tetherHintDetails.tetherWindow.orderFrontRegardless()
    }
    
    private func updateTetherWindowPosition(for screen: NSScreen, lastYComputed: CGFloat? = nil) {
        let activeScreenFrame = screen.visibleFrame
        let positionX = activeScreenFrame.maxX - ExternalTetheredButton.containerWidth
        let positionY = activeScreenFrame.minY + (activeScreenFrame.height / 2) - (ExternalTetheredButton.containerHeight / 2)
        
        let frame = NSRect(
            x: positionX,
            y: positionY,
            width: ExternalTetheredButton.containerWidth,
            height: ExternalTetheredButton.containerHeight
        )
        tetherHintDetails.tetherWindow.setFrame(frame, display: false)
    }

    private func tetheredWindowMoved(y: CGFloat) {
        if let tetherPanelState = tetherButtonPanelState, 
           let screen = tetherPanelState.trackedScreen {
            if tetherPanelState.panelOpened {
                tetherPanelState.closePanel()
            } else {
                tetherPanelState.launchPanel()
            }
        }
    }
}


extension PanelStatePinnedManager: AccessibilityNotificationsDelegate {
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        if let windowFrame = window.element.getFrame(convertedToGlobalCoordinateSpace: true),
           let screen = windowFrame.findScreen() {
            let panelState = getState(for: screen)
            
            handlePanelStateChange(state: panelState)
        }
    }
    
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateIgnoredWindow window: TrackedWindow?) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMinimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDeminimizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didMoveWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didResizeWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didDestroyWindow window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didReceiveTextSelection text: String, from window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didReceiveSelectedText text: String, from window: TrackedWindow) {}
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didReceiveClipboardText text: String) {}
}

extension PanelStatePinnedManager: OnitPanelStateDelegate {
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
    
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) {}
}
