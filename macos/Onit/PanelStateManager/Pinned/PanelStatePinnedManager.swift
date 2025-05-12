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
    
    // MARK: - Singleton instance

    static let shared = PanelStatePinnedManager()
    
    // MARK: - Properties
    
    private var lastScreenFrame = CGRect.zero
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
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
        
        states = [defaultState]
    }

    // MARK: - Functions

    override func start() {
        stop()

        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return }
            activateMouseScreen()
        }
        
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            guard let self = self else { return event }
            activateMouseScreen()
            return event
        }
        
        AccessibilityNotificationsManager.shared.addDelegate(self)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        
        state.addDelegate(self)
        
        activateMouseScreen(forced: true)
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
        lastScreenFrame = .zero
        AccessibilityNotificationsManager.shared.removeDelegate(self)
        NotificationCenter.default.removeObserver(self)
        
        state.removeDelegate(self)
        
        super.stop()
    }

    @objc private func applicationWillTerminate() {
        resetFramesOnAppChange()
    }
    
    func handlePanelStateChange() {
         if !state.panelOpened {
             state.trackedScreen = nil
             
             activateMouseScreen(forced: true)
         }
    }
    
    private func activateMouseScreen(forced: Bool = false) {
        if forced {
            lastScreenFrame = .zero
        }
        if let mouseScreen = NSScreen.mouse {
            if !mouseScreen.frame.equalTo(lastScreenFrame) {
                handleActivation(of: mouseScreen)
                lastScreenFrame = mouseScreen.frame
            }
        }
    }
    
    private func handleActivation(of screen: NSScreen) {
        if state.trackedScreen != screen {
            debouncedShowTetherWindow(activeScreen: screen)
        } else {
            hideTetherWindow()
        }
        
//        handlePanelStateChange()
    }
    
    override func hideTetherWindow() {
        super.hideTetherWindow()
        
        tutorialWindow.orderOut(nil)
        tutorialWindow.contentView = nil
    }
}


extension PanelStatePinnedManager: AccessibilityNotificationsDelegate {
    func accessibilityManager(_ manager: AccessibilityNotificationsManager, didActivateWindow window: TrackedWindow) { }
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
        handlePanelStateChange()
    }
    func userInputsDidChange(instruction: String, contexts: [Context], input: Input?) {}
}
