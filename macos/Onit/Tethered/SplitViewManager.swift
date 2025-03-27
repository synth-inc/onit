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
    
    private var regularAppCancellable: AnyCancellable?
    private var otherCancellables = Set<AnyCancellable>()
    
    private let minOnitWidth: CGFloat = ContentView.idealWidth
    private let spaceBetweenWindows: CGFloat = -(TetheredButton.width / 2)
    
    @Published private var targetApplicationPID: pid_t?
    private var targetInitialFrame: CGRect?
    
    private var tetherWindow: NSWindow?
    private var lastYComputed: CGFloat?
    private var dragDebounce: AnyCancellable?
    
    private var shouldLog = false
    
    // MARK: - Private initializer
    private init() { }
    
    // MARK: - Functions
    func configure(model: OnitModel) {
        self.model = model
    }
    
    func startObserving() {
        stopObserving()

        let isRegularAppPublisher = Defaults.publisher(.isRegularApp)
            .map(\.newValue)
        
        regularAppCancellable = isRegularAppPublisher
            .sink { [weak self] isRegularApp in
                if isRegularApp {
                    self?.startAllObservers()
                } else {
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
        
        // App State Observer
        Publishers.CombineLatest(fitActiveWindowPublisher, isPanelOpenedAndNotMinimized)
            .sink(receiveValue: appStateObserver)
            .store(in: &otherCancellables)
        
        // Window Visibility Observer
        Publishers.CombineLatest(activeWindowElement, $targetApplicationPID)
            .sink(receiveValue: tetheredWindowVisibilityObserver)
            .store(in: &otherCancellables)
        
        // Window Positioning Observer
        Publishers.CombineLatest3(activeWindowElement, isPanelOpenedAndNotMinimized, fitActiveWindowPublisher)
            .sink(receiveValue: windowPositioningObserver)
            .store(in: &otherCancellables)
    }
    
    private func stopAllObservers() {
        otherCancellables.removeAll()
        hideTetherWindow()
    }
    
    // MARK: - Observers
    private func appStateObserver(isTethered: Bool, isPanelOpened: Bool) {
        if shouldLog {
            print("SplitViewManager - appStateObserver - isTethered: \(isTethered), isPanelOpened: \(isPanelOpened)")
        }
        
        // If we're untethering, restore the window frame first
        if !isTethered {
            if let pid = self.targetApplicationPID,
               let initialFrame = self.targetInitialFrame,
               let window = pid.getAXUIElement().children()?.first {
                _ = window.setFrame(initialFrame)
            }
            
            self.targetApplicationPID = nil
            self.targetInitialFrame = nil
            self.model?.panel?.level = .floating
            return
        }
        
        // If we're tethering and panel is opened
        if isTethered && isPanelOpened {
            // Only update if we don't have a target or if the target has changed
            if let window = AccessibilityNotificationsManager.shared.activeWindowElement,
               window.pid() != self.targetApplicationPID {
                self.targetInitialFrame = window.frame()
                
                if let pid = window.pid() {
                    self.targetApplicationPID = pid
                    self.model?.panel?.level = .floating
                }
            }
        }
    }
    
    private func tetheredWindowVisibilityObserver(activeWindow: AXUIElement?, targetPID: pid_t?) {
        if shouldLog {
            print("SplitViewManager - tetheredWindowVisibilityObserver - targetPID \(String(describing: targetPID)), activeWindow pid \(String(describing: activeWindow?.pid()))")
        }
        let shouldShowTether = targetPID == nil || activeWindow?.pid() != targetPID
        
        if shouldShowTether {
            self.showTetherWindow(activeWindow: activeWindow)
        } else {
            self.hideTetherWindow()
        }
    }
    
    private func windowPositioningObserver(window: AXUIElement?, isPanelOpened: Bool, isTethered: Bool) {
        guard isTethered,
              isPanelOpened,
              let window = window,
              let currentPID = window.pid() else {
            if shouldLog {
                print("SplitViewManager - windowPositioningObserver - ERROR isTethered:\(isTethered) isPanelOpened:\(isPanelOpened) windowIsNil:\(window == nil) windowPidIsNil:\(window?.pid() == nil)")
            }
            return
        }
        if shouldLog {
            print("SplitViewManager - windowPositioningObserver - isPanelOpened: \(isPanelOpened), isTethered: \(isTethered) isTetheredApp \(currentPID == self.targetApplicationPID)")
        }
        
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
              let size = window.size() else {
            if shouldLog {
                print("SplitViewManager - repositionWindow - ERROR")
            }
            return
        }
        if shouldLog {
            print("SplitViewManager - repositionWindow - position: \(position), size: \(size)")
        }
        guard let screen = NSRect(origin: position, size: size).findScreen() else { return }
        
        let screenFrame = screen.frame
        let onitWidth = minOnitWidth
        let onitHeight = min(size.height, screenFrame.height - ContentView.bottomPadding)
        let onitY = screenFrame.maxY - (position.y + onitHeight)
        
        let spaceOnRight = screenFrame.maxX - (position.x + size.width)
        let hasEnoughSpace = spaceOnRight >= onitWidth + spaceBetweenWindows
        
        if hasEnoughSpace {
            let onitX = position.x + size.width + spaceBetweenWindows
            
            panel.setFrame(NSRect(
                x: onitX,
                y: onitY,
                width: onitWidth,
                height: onitHeight
            ), display: true, animate: true)
        } else {
            let maxActiveAppWidth = screenFrame.width - onitWidth - spaceBetweenWindows
            let activeAppWidth = min(size.width, maxActiveAppWidth)
            
            if window.setFrame(CGRect(
                x: position.x,
                y: position.y,
                width: activeAppWidth,
                height: size.height
            )) {
                let onitX = position.x + activeAppWidth + spaceBetweenWindows
                
                panel.setFrame(NSRect(
                    x: onitX,
                    y: onitY,
                    width: onitWidth,
                    height: onitHeight
                ), display: true, animate: true)
            }
        }
    }

    private func showTetherWindow(activeWindow: AXUIElement?) {
        hideTetherWindow()
        if shouldLog {
            print("SplitViewManager - showTetherWindow")
        }
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
        window.orderFront(nil)
        
        self.tetherWindow = window
        updateTetherWindowPosition(for: activeWindow)
    }
    
    private func hideTetherWindow() {
        tetherWindow?.close()
        tetherWindow = nil
    }
    
    private func updateTetherWindowPosition(for window: AXUIElement?) {
        guard let tetherWindow = tetherWindow,
              let activeWindow = window,
              let size = activeWindow.size(),
              let position = activeWindow.position() else {
            if shouldLog {
                print("SplitViewManager - updateTetherWindowPosition - ERROR tetherWindowIsNil:\(tetherWindow == nil) activeWindowIsNil:\(window == nil) size: \(window?.size()) position: \(window?.position())")
            }
            return
        }
        if shouldLog {
            print("SplitViewManager - updateTetherWindowPosition - size \(size) position \(position)")
        }
        
        if lastYComputed == nil {
            lastYComputed = (size.height / 2) - (TetheredButton.height / 2)
        } else {
            lastYComputed = computeTetheredWindowY(activeWindow: activeWindow, offset: nil)
        }
        guard let lastYComputed = lastYComputed else { return }
        
        let frame = NSRect(
            x: position.x + size.width - TetheredButton.width,
            y: lastYComputed,
            width: TetheredButton.width,
            height: TetheredButton.height
        )
        
        tetherWindow.setFrame(frame, display: true)
    }
    
    func tetheredWindowMoved(y: CGFloat) {
        guard let activeWindow = AccessibilityNotificationsManager.shared.activeWindowElement else {
            if shouldLog {
                print("SplitViewManager - tetheredWindowMoved - ERROR")
            }
            return
        }
        
        if shouldLog {
            print("SplitViewManager - tetheredWindowMoved")
        }
        
        self.lastYComputed = computeTetheredWindowY(activeWindow: activeWindow, offset: y)
        self.updateTetherWindowPosition(for: activeWindow)
    }
    
    private func computeTetheredWindowY(activeWindow: AXUIElement, offset: CGFloat?) -> CGFloat? {
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
