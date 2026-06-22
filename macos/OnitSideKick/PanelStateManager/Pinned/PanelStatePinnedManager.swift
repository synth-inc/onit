//
//  PanelStatePinnedManager.swift
//  Onit
//
//  Created by Timothy Lenardo on 07/05/25.
//

import AppKit
import Combine
import Defaults
import PostHog
import SwiftUI

@MainActor
class PanelStatePinnedManager: PanelStateBaseManager, ObservableObject {
    
    // MARK: - Singleton instance

    static let shared = PanelStatePinnedManager()
    
    // MARK: - Properties

    var isResizingWindows: Bool = false
    var shouldResizeWindows: Bool = false

    private var lastScreenFrame = CGRect.zero
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    
    var attachedScreen: NSScreen?
    
    /// Dragging
    let dragManager = GlobalDragManager()
    var dragManagerCancellable: AnyCancellable?
    var draggingWindow: AXUIElement?
    
    // MARK: - Initializer
    
    private override init() {
        super.init()
        
        states = []
    }

    // MARK: - PanelStateManagerLogic
    
    override var isPanelMovable: Bool { false }

    override func start() {
        stop()

        let state = OnitPanelState()
        
        self.state = state
        states = [state]
        state.subscribeAsHighlightedTextDelegate()
        
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
        
        dragManagerCancellable = dragManager.$isDragging
            .sink { [weak self] isDragging in
                if !isDragging {
                    self?.onActiveWindowDragEnded()
                }
            }
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appLaunchedReceived),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil)
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(spaceChangedReceived),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(applicationWillTerminate),
            name: NSApplication.willTerminateNotification,
            object: nil
        )
        
        state.addDelegate(self)
        
        dragManager.startMonitoring()
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
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        dragManager.stopMonitoring()
        dragManagerCancellable?.cancel()
        draggingWindow = nil
        state.unsubscribeAsHighlightedTextDelegate()
        state.removeDelegate(self)

        HintManager.shared.lastYComputed = nil

        super.stop()
    }
    
    override func getState(for windowHash: UInt) -> OnitPanelState? {
        return state
    }
    
    override func filterHistoryChats(_ chats: [Chat]) -> [Chat] {
        return super.filterHistoryChats(chats)
    }
    
    override func filterPanelChats(_ chats: [Chat]) -> [Chat] {
        return super.filterPanelChats(chats)
    }
    
    override func launchPanel(for state: OnitPanelState, createNewChat: Bool) {
        AnalyticsManager.Panel.opened(displayMode: "pinned")
        shouldResizeWindows = true
        
        hideTetherWindow()
        
        attachedScreen = NSScreen.mouse
        
        buildPanelIfNeeded(for: state, createNewChat: createNewChat)
        showPanel(for: state)
        
        // Add initial context for the current foreground window if auto context is enabled
        if Defaults[.autoContextOnLaunchPinned], let foregroundWindow = state.foregroundWindow {
            // Use the ContextFetchingService to add context for the new window
            ContextFetchingService.shared.retrieveWindowContent(
                state: state,
                trackedWindow: foregroundWindow,
                wasTriggeredAutomatically: true
            )
        }
    }
    
    override func closePanel(for state: OnitPanelState) {
        AnalyticsManager.Panel.closed(displayMode: "pinned")
        shouldResizeWindows = false
        
        // Remove any auto context that was added for Pinned mode
        if Defaults[.autoContextOnLaunchPinned], let foregroundWindow = state.foregroundWindow {
            removeAutoContextForWindow(foregroundWindow, in: state)
        }
        
        hidePanel(for: state)
        
        super.closePanel(for: state)
    }

    // MARK: - Functions
    
    /// Removes auto context for a specific window and cleans up related tasks
    private func removeAutoContextForWindow(_ window: TrackedWindow, in state: OnitPanelState) {
        // Cancel any pending context fetching tasks for this window to prevent
        // addAutoContext from being called when they complete
        state.cleanupWindowContextTask(uniqueWindowIdentifier: window.hash)
        
        // Find and remove any auto context that matches the window
        let contextToRemove = state.pendingContextList.first { context in
            if case .auto(let autoContext) = context {
                return autoContext.appHash == window.hash && autoContext.appTitle == window.title
            }
            return false
        }

        if let contextToRemove = contextToRemove {
            state.pendingContextList.removeAll { $0 == contextToRemove }
            ContextWindowsManager.shared.deleteContextItem(item: contextToRemove)
        }
    }
    
    @objc private func appLaunchedReceived(notification: Notification) {
        guard state.panelOpened, let screen = state.panel?.screen, let userInfo = notification.userInfo else { return }
        
        guard let app = (userInfo[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication) ??
                (userInfo["NSWorkspaceApplicationKey"] as? NSRunningApplication) else { return }
        
        let previousForegroundWindow = state.foregroundWindow
        state.foregroundWindow = AccessibilityNotificationsManager.shared.windowsManager.trackWindowForElement(
            app.processIdentifier.getAXUIElement(),
            pid: app.processIdentifier
        )
        
        // Handle automatic context change if auto context is enabled
        if Defaults[.autoContextOnLaunchPinned], let newForegroundWindow = state.foregroundWindow {
            // Remove context from the previous window if it exists
            if let previousForegroundWindow = previousForegroundWindow {
                removeAutoContextForWindow(previousForegroundWindow, in: state)
            }
            
            // Add context for the new window
            ContextFetchingService.shared.retrieveWindowContent(
                state: state,
                trackedWindow: newForegroundWindow,
                wasTriggeredAutomatically: true
            )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            let windows = app.processIdentifier.getWindows()
            
            for window in windows {
                self?.resizeWindow(for: screen, window: window)
            }
        }
    }
    
    @objc private func spaceChangedReceived(notification: Notification) {
        guard state.panelOpened, let panel = state.panel, let screen = panel.screen else { return }

        panel.orderFrontRegardless()
        
        resizeWindows(for: screen)
    }

    @objc private func applicationWillTerminate() {
        resetFramesOnAppChange()
    }
    
    func activateMouseScreen(forced: Bool = false) {
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
        if attachedScreen != screen {
            debouncedShowTetherWindow(activeScreen: screen)
        } else {
            hideTetherWindow()
        }
    }
    
    func checkIfDragStarted(window: AXUIElement) -> Bool {
        guard dragManager.isDragging else { return false }
        guard draggingWindow == nil else { return true }
        
        draggingWindow = window
        
        return true
    }
    
    private func onActiveWindowDragEnded() {
        guard let window = draggingWindow else { return }
        
        draggingWindow = nil
        
        guard let mouseScreen = NSScreen.mouse,
              let panelScreen = state.panel?.screen else { return }
        
        if mouseScreen === panelScreen {
            resizeWindow(for: panelScreen, window: window, windowFrameChanged: true)
        } else {
            targetInitialFrames.removeValue(forKey: window)
        }
    }
    
    override func resetFramesOnAppChange() {
        let panelWidth = state.panelWidth - (TetheredButton.width / 2) + 1
        let screenFrame = self.attachedScreen?.visibleFrame ?? NSScreen.main?.visibleFrame ?? .zero
        let panelMinX = screenFrame.maxX - panelWidth
        let capturedForegroundWindow = state.foregroundWindow
        
        // Handle bordering window first.
        // These are the only ones users can see, so we can handle them synchronously. This creates the desired visual experience.
        var borderingWindows = self.findBorderingWindows().compactMap { $0 }
        if let foregroundWindow = capturedForegroundWindow?.element, !borderingWindows.contains(where: { $0 == foregroundWindow }) {
            borderingWindows.append(foregroundWindow)
        }
        for window in borderingWindows {
            if let currentFrame = window.getFrame() {
                let isNearOrUnderPanel = currentFrame.maxX > (panelMinX - 2) && currentFrame.maxX <= screenFrame.maxX
                if isNearOrUnderPanel {
                    let newWidth = currentFrame.width + panelWidth
                    let newFrame = NSRect(origin: currentFrame.origin,
                                          size: NSSize(width: newWidth, height: currentFrame.height))
                    _ = window.setFrame(newFrame)
                }
            }
        }
        
        // Delay it until after our main animation finishes (hopefully)
        // The other window resizes are expensive, so we don't want them interfering with animation.
        DispatchQueue.main.asyncAfter(deadline: .now() + (animationDuration + 0.1)) {
            let windows = WindowHelpers.getAllOtherAppWindows()

            for window in windows {
                // Skip the foreground element, since we've already done it.
                if let foregroundWindow = capturedForegroundWindow, window != foregroundWindow.element {
                    if let currentFrame = window.getFrame() {
                        let isNearOrUnderPanel = currentFrame.maxX > (panelMinX - 2) && currentFrame.maxX <= screenFrame.maxX
                        if isNearOrUnderPanel {
                            let newWidth = currentFrame.width + panelWidth
                            let newFrame = NSRect(origin: currentFrame.origin,
                                                  size: NSSize(width: newWidth, height: currentFrame.height))
                            // As a best practice, we dispatch these so they other tasks can use the main thread in between.
                            DispatchQueue.main.async {
                                _ = window.setFrame(newFrame)
                            }
                        }
                    }
                }
            }
        }
    }
}
