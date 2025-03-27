//
//  SplitViewManager.swift
//  Onit
//
//  Created by Kévin Naudin on 12/03/2025.
//

import AppKit
import Combine
import Defaults
import SwiftUI

@MainActor
class SplitViewManager: ObservableObject {
    
    // MARK: - Singleton instance
    static let shared = SplitViewManager()
    
    // MARK: - Properties
    private var model: OnitModel?
    private var cancellables = Set<AnyCancellable>()
    
    private let minOnitWidth: CGFloat = ContentView.idealWidth
    private let spaceBetweenWindows: CGFloat = -(TetheredButton.width / 2)
    
    @Published private var targetApplicationPID: pid_t?
    private var targetInitialFrame: CGRect?
    private var tetherWindow: NSWindow?
    private var lastYComputed: CGFloat?
    private var dragDebounce: AnyCancellable?
    
    // MARK: - Private initializer
    private init() { }
    
    // MARK: - Functions
    func configure(model: OnitModel) {
        self.model = model
    }
    
    func startObserving() {
        stopObserving()

        guard let model = model else { return }
        
        let activeWindowElement = AccessibilityNotificationsManager.shared.$activeWindowElement
        let isPanelOpened = model.isPanelOpened
            .prepend(model.panel != nil)
        let isPanelMiniaturized = model.isPanelMiniaturized
            .prepend(model.panel?.isMiniaturized ?? false)
        let isPanelOpenedAndNotMinimized = Publishers.CombineLatest(isPanelOpened, isPanelMiniaturized)
            .map { $0 && !$1 }
        let fitActiveWindowPublisher = Defaults.publisher(.fitActiveWindow)
            .map(\.newValue)
        let isRegularAppPublisher = Defaults.publisher(.isRegularApp)
            .map(\.newValue)
        
        Publishers.CombineLatest(fitActiveWindowPublisher, isPanelOpenedAndNotMinimized)
            .sink(receiveValue: appStateObserver)
            .store(in: &cancellables)
        
        Publishers.CombineLatest3(isRegularAppPublisher, activeWindowElement, $targetApplicationPID)
            .sink(receiveValue: tetheredWindowVisibilityObserver)
            .store(in: &cancellables)

        Publishers.CombineLatest(activeWindowElement, $targetApplicationPID)
            .sink(receiveValue: tetheredWindowPositionObserver)
            .store(in: &cancellables)
        
        Publishers.CombineLatest3(activeWindowElement, isPanelOpenedAndNotMinimized, fitActiveWindowPublisher)
            .sink(receiveValue: windowPositioningObserver)
            .store(in: &cancellables)
    }
    
    // MARK: - Private functions
    private func stopObserving() {
        cancellables.removeAll()
        hideTetherWindow()
    }
    
    // MARK: - Observers
    private func appStateObserver(isTethered: Bool, isPanelOpened: Bool) {
        if isTethered && isPanelOpened {
            // Restore previous tethered window if exists
            if let previousPID = self.targetApplicationPID,
               let previousFrame = self.targetInitialFrame,
               let previousWindow = previousPID.getAXUIElement().children()?.first {
                _ = previousWindow.setFrame(previousFrame)
            }
            
            if let window = AccessibilityNotificationsManager.shared.activeWindowElement {
                self.targetInitialFrame = window.frame()
                
                if let pid = window.pid() {
                    self.targetApplicationPID = pid
                    self.model?.panel?.level = .floating
                }
            }
        } else {
            if let pid = self.targetApplicationPID,
               let initialFrame = self.targetInitialFrame,
               let window = pid.getAXUIElement().children()?.first {
                
                _ = window.setFrame(initialFrame)
            }
            
            self.targetApplicationPID = nil
            self.targetInitialFrame = nil
            self.model?.panel?.level = .floating
        }
    }
    
    private func tetheredWindowVisibilityObserver(
        isRegularApp: Bool,
        activeWindow: AXUIElement?,
        targetPID: pid_t?
    ) {
        let shouldShowTether = isRegularApp && (targetPID == nil || activeWindow?.pid() != targetPID)
        
        if shouldShowTether {
            self.showTetherWindow()
        } else {
            self.hideTetherWindow()
        }
    }
    
    private func tetheredWindowPositionObserver(window: AXUIElement?, targetPID: pid_t?) {
        updateTetherWindowPosition(for: window)
    }
    
    private func windowPositioningObserver(window: AXUIElement?, isPanelOpened: Bool, isTethered: Bool) {
        guard Defaults[.isRegularApp],
              isTethered,
              isPanelOpened,
              let window = window,
              let currentPID = window.pid() else { return }
        
        if currentPID == self.targetApplicationPID {
            self.model?.panel?.level = .floating
            self.repositionWindow(window: window)
        } else {
            self.model?.panel?.level = .normal
        }
    }
    
    private func repositionWindow(window: AXUIElement) {
        guard let panel = model?.panel,
              let position = window.position(),
              let size = window.size() else { return }
        
        guard let screen = NSRect(origin: position, size: size).findScreen() else { return }
        
        let screenFrame = screen.visibleFrame
        let maxActiveAppWidth = screenFrame.width - minOnitWidth - spaceBetweenWindows
        let activeAppWidth = min(size.width, maxActiveAppWidth)
        
        let relativeX = max(position.x - screenFrame.minX, 0)
        let relativeOnitX = relativeX + activeAppWidth + spaceBetweenWindows
        let onitX = screenFrame.minX + min(relativeOnitX, screenFrame.width - minOnitWidth)
        let onitWidth = max(minOnitWidth, screenFrame.maxX - onitX)
        let onitHeight = screenFrame.height - ContentView.bottomPadding
        let onitY = screenFrame.minY + (screenFrame.height - onitHeight)
        
        if window.setFrame(CGRect(
            x: position.x,
            y: position.y,
            width: activeAppWidth,
            height: size.height
        )) {
            panel.setFrame(NSRect(
                x: onitX,
                y: onitY,
                width: onitWidth,
                height: onitHeight
            ), display: true, animate: true)
        }
    }

    private func showTetherWindow() {
        guard tetherWindow == nil else { return }
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: TetheredButton.width, height: TetheredButton.height),
            styleMask: [.borderless, .titled],
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
        
        let buttonView = NSHostingView(rootView: TetheredButton(
            onDrag: { [weak self] translation in
                self?.tetheredWindowMoved(y: translation)
            }
        ))
        buttonView.wantsLayer = true
        buttonView.layer?.cornerRadius = TetheredButton.width / 2
        buttonView.layer?.masksToBounds = true
        buttonView.layer?.backgroundColor = .clear
        
        window.contentView = buttonView
        window.makeKeyAndOrderFront(nil)
        
        self.tetherWindow = window
        updateTetherWindowPosition(for: AccessibilityNotificationsManager.shared.activeWindowElement)
    }
    
    private func hideTetherWindow() {
        tetherWindow?.close()
        tetherWindow = nil
    }
    
    private func updateTetherWindowPosition(for window: AXUIElement?) {
        guard let tetherWindow = tetherWindow,
              let activeWindow = window,
              let size = activeWindow.size(),
              let position = activeWindow.position() else { return }
        
        if lastYComputed == nil {
            lastYComputed = (size.height / 2) - (TetheredButton.height / 2)
        } else {
            lastYComputed = computeFinalY(activeWindow: activeWindow, offset: nil)
        }
        
        let frame = NSRect(
            x: position.x + size.width - TetheredButton.width,
            y: lastYComputed!,
            width: TetheredButton.width,
            height: TetheredButton.height
        )
        
        tetherWindow.setFrame(frame, display: true)
    }
    
    func tetheredWindowMoved(y: CGFloat) {
        guard let activeWindow = AccessibilityNotificationsManager.shared.activeWindowElement else {
            return
        }
        
        self.lastYComputed = computeFinalY(activeWindow: activeWindow, offset: y)
        self.updateTetherWindowPosition(for: activeWindow)
    }
    
    private func computeFinalY(activeWindow: AXUIElement, offset: CGFloat?) -> CGFloat? {
        guard let position = activeWindow.position(),
              let size = activeWindow.size(),
              let screenFrame = NSScreen.main?.visibleFrame else { return nil }
        
        let maxY = (screenFrame.maxY - screenFrame.minY) - position.y
        let minY = maxY - size.height + TetheredButton.height
        
        let lastYComputed: CGFloat
        if let offset = offset {
            lastYComputed = self.lastYComputed! - offset
        } else {
            lastYComputed = self.lastYComputed!
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
}
