//
//

import AppKit
import Defaults
import SwiftUI

@MainActor
class AccessibilityScreenManager: ObservableObject {


    static let shared = AccessibilityScreenManager()
    
    
    @Published var state: OnitPanelState
    @Published var tetherButtonPanelState: OnitPanelState?
    var states: [TrackedScreen: OnitPanelState] = [:]
    var isObserving: Bool = false
    
    private let defaultState = OnitPanelState(trackedScreen: nil)
    
    static let minOnitWidth: CGFloat = ContentView.idealWidth
    static let spaceBetweenWindows: CGFloat = -(TetheredButton.width / 2)
    
    var tetherHintDetails: TetherHintDetails
    var tutorialWindow: NSWindow
    
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


    func startObserving() {
        stopObserving()
        isObserving = true
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

    func stopObserving() {
        isObserving = false
        NotificationCenter.default.removeObserver(self)
        AccessibilityNotificationsManager.shared.removeDelegate(self)
        hideTetherWindow()
    }

    @objc private func appDidBecomeActive(_ notification: Notification) { }

    @objc private func applicationWillTerminate() { }
    
    func handlePanelStateChange(state: OnitPanelState, action: TrackedScreenAction) {
        guard let screen = state.trackedScreen else {
            return
        }

        if !state.hidden {
            if state.panelOpened {
                hideTetherWindow()
                showPanelForScreen(state: state, screen: screen)
            } else {
                debouncedShowTetherWindow(state: state, activeScreen: screen, action: action)
            }
        } else {
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
    
    func showPanelForScreen(state: OnitPanelState, screen: TrackedScreen) {
        guard let panel = state.panel else { return }
        
        let screenFrame = screen.screen.visibleFrame
        let onitWidth = AccessibilityScreenManager.minOnitWidth
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
                let maxWidth = panelFrame.minX - windowFrame.minX - AccessibilityScreenManager.spaceBetweenWindows
                
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

    func debouncedShowTetherWindow(state: OnitPanelState, activeScreen: TrackedScreen, action: TrackedScreenAction) {
        hideTetherWindow()
        let pendingTetherWindow = (state, activeScreen)

        tetherHintDetails.showTetherDebounceTimer?.invalidate()
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
        tetherHintDetails.showTetherDebounceTimer?.invalidate()
        tetherHintDetails.showTetherDebounceTimer = nil
        tetherButtonPanelState = nil

        tetherHintDetails.tetherWindow.orderOut(nil)
        tetherHintDetails.tetherWindow.contentView = nil
        tetherHintDetails.lastYComputed = nil
        
        tutorialWindow.orderOut(nil)
        tutorialWindow.contentView = nil
    }

    func showTetherWindow(state: OnitPanelState, activeScreen: NSScreen, action: TrackedScreenAction) {
         let tetherView = ExternalTetheredButton(
             onDrag: { [weak self] translation in
                 self?.tetheredWindowMoved(y: translation)
             }
         ).environment(\.windowState, state)

        let buttonView = NSHostingView(rootView: tetherView)
        tetherHintDetails.tetherWindow.contentView = buttonView
        tetherHintDetails.lastYComputed = nil
        tetherButtonPanelState = state

        updateTetherWindowPosition(for: activeScreen, action: action, lastYComputed: tetherHintDetails.lastYComputed)
        tetherHintDetails.tetherWindow.orderFrontRegardless()
    }
    
    private func updateTetherWindowPosition(for screen: NSScreen, action: TrackedScreenAction, lastYComputed: CGFloat? = nil) {
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


extension AccessibilityScreenManager: AccessibilityNotificationsDelegate {
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) {
        if let windowFrame = window.element.getFrame(convertedToGlobalCoordinateSpace: true),
           let screen = windowFrame.findScreen(),
           let trackedScreenManager = TrackedScreenManager.shared.append(screen: screen) {
            let panelState = getState(for: trackedScreenManager)
            handlePanelStateChange(state: panelState, action: .activate)
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


extension AccessibilityScreenManager: OnitPanelStateDelegate {
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
    
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) {}
}
