//
//  QuickEditWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 06/10/2025.
//

import AppKit
import SwiftUI

@MainActor
class QuickEditWindowController: NSObject, NSWindowDelegate {
    
    // MARK: - Constants
    
    private enum Constants {
        static let escapeKeyCode: UInt16 = 53
        static let sizeToleranceThreshold: CGFloat = 1.0
        static let sizeDifferenceThreshold: CGFloat = 2.0
        static let resizeTimerInterval: TimeInterval = 0.05
        static let activationDelay: TimeInterval = 0.05
        static let transparencyAnimationDuration: TimeInterval = 0.3
        static let resizeAnimationDuration: TimeInterval = 0.1
        static let mouseInAlpha: CGFloat = 1.0
        static let mouseOutAlpha: CGFloat = 0.7
        static let estimatedWindowSize = CGSize(width: 360, height: 120)
    }
    
    // MARK: - QuickEditWindow
    
    class QuickEditWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { false }
    }
    
    // MARK: - MouseTrackingView
    
    class MouseTrackingView: NSView {
        weak var windowController: QuickEditWindowController?
        
        // Uncomment this to set transparency back
//        override func updateTrackingAreas() {
//            super.updateTrackingAreas()
//
//            trackingAreas.forEach { removeTrackingArea($0) }
//            
//            let trackingArea = NSTrackingArea(
//                rect: bounds,
//                options: [.mouseEnteredAndExited, .activeInActiveApp],
//                owner: self,
//                userInfo: nil
//            )
//			
//            addTrackingArea(trackingArea)
//        }
//        
//        override func mouseEntered(with event: NSEvent) {
//            windowController?.setWindowTransparency(isMouseInside: true)
//        }
//        
//        override func mouseExited(with event: NSEvent) {
//            windowController?.setWindowTransparency(isMouseInside: false)
//        }
        
        override func layout() {
            super.layout()

            DispatchQueue.main.async {
                self.windowController?.updateWindowSize()
            }
        }
    }
    
    // MARK: - Properties
    
    var window: NSWindow?
    
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private var hintPosition: CGPoint = .zero
    private var hintHeight: CGFloat?
    private var resizeTimer: Timer?
    private var pendingSize: CGSize?
    private var isResizing: Bool = false
    private var lastProcessedSize: CGSize = .zero
    private var isInitialDisplay: Bool = true
    
    // MARK: - Functions
    
    func show(at position: CGPoint, hintHeight: CGFloat?) {
        hintPosition = position
        self.hintHeight = hintHeight
        
        if let window = window {
            let newPosition = calculateOptimalPosition()
            window.setFrameOrigin(newPosition)
            window.orderFront(nil)
            window.makeKey()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.forceActivation()
            }
            return
        }
        
        createWindow(at: hintPosition)
    }
    
    func hide() {
        window?.orderOut(nil)
        window = nil
        hintHeight = nil
        stopEventMonitoring()
        cleanupResizeState()
    }
    
    // MARK: - Private functions
    
    private func createWindow(at position: CGPoint) {
        let windowState = PanelStateCoordinator.shared.state
		
        let contentView = QuickEditView()
            .environment(\.windowState, windowState)
        let hostingController = NSHostingController(rootView: contentView)
        
        let trackingView = MouseTrackingView()
        trackingView.windowController = self
        trackingView.translatesAutoresizingMaskIntoConstraints = false
        
        trackingView.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: trackingView.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: trackingView.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: trackingView.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: trackingView.bottomAnchor),
            
            trackingView.widthAnchor.constraint(equalTo: hostingController.view.widthAnchor),
            trackingView.heightAnchor.constraint(equalTo: hostingController.view.heightAnchor)
        ])
        
        window = QuickEditWindow()
        window?.contentView = trackingView
        window?.styleMask = [.borderless]
        window?.isOpaque = false
        window?.backgroundColor = NSColor.clear
        
        window?.contentView?.needsLayout = true
        window?.level = .floating
        window?.delegate = self
        window?.isReleasedWhenClosed = false
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.isMovable = true
        window?.isMovableByWindowBackground = true
        
        let optimalPosition = calculateTargetPosition(for: Constants.estimatedWindowSize)
        
		window?.setFrameOrigin(optimalPosition)
        window?.alphaValue = 0.0
        window?.orderFront(nil)
        window?.makeKey()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.forceActivation()
            self.updateWindowSize()
            self.checkInitialMousePosition()
        }
        
        startEventMonitoring()
    }
    
    private func startEventMonitoring() {
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == Constants.escapeKeyCode {
                self?.hide()
                return nil
            }
            return event
        }
        
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == Constants.escapeKeyCode {
                self?.hide()
            }
        }
    }
    
    private func stopEventMonitoring() {
        if let localEventMonitor = localEventMonitor {
            NSEvent.removeMonitor(localEventMonitor)
            self.localEventMonitor = nil
        }
        
        if let globalEventMonitor = globalEventMonitor {
            NSEvent.removeMonitor(globalEventMonitor)
            self.globalEventMonitor = nil
        }
    }
    
    private func forceActivation() {
        window?.makeKey()
        
        NSApp.activate(ignoringOtherApps: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.window?.makeKey()
            self.window?.orderFront(nil)
            
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    private func setWindowTransparency(isMouseInside: Bool) {
        guard let window = window else { return }
        
        let targetAlpha: CGFloat = Constants.mouseInAlpha
        // Uncomment this to set transparency back
        // let targetAlpha: CGFloat = isMouseInside ? Constants.mouseInAlpha : Constants.mouseOutAlpha
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Constants.transparencyAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = targetAlpha
        }
    }
    
    private func cleanupResizeState() {
        resizeTimer?.invalidate()
        resizeTimer = nil
        pendingSize = nil
        isResizing = false
        lastProcessedSize = .zero
        isInitialDisplay = true
        hintHeight = nil
    }
    
    private func shouldSkipSizeUpdate(fittingSize: CGSize, currentFrame: CGRect) -> Bool {
        let hasMinimalChange = abs(fittingSize.width - lastProcessedSize.width) <= Constants.sizeToleranceThreshold &&
                              abs(fittingSize.height - lastProcessedSize.height) <= Constants.sizeToleranceThreshold &&
                              abs(currentFrame.width - lastProcessedSize.width) <= Constants.sizeToleranceThreshold &&
                              abs(currentFrame.height - lastProcessedSize.height) <= Constants.sizeToleranceThreshold
        
        let widthDiff = abs(fittingSize.width - currentFrame.width)
        let heightDiff = abs(fittingSize.height - currentFrame.height)
        let hasSmallDifference = widthDiff <= Constants.sizeDifferenceThreshold && heightDiff <= Constants.sizeDifferenceThreshold
        
        return hasMinimalChange || hasSmallDifference
    }
    
    func updateWindowSize() {
        guard let window = window,
              let contentView = window.contentView,
			  !isResizing else {
            return
        }
        
        contentView.needsLayout = true
        contentView.layoutSubtreeIfNeeded()
        
        let fittingSize = contentView.fittingSize
        let currentFrame = window.frame
        
        if shouldSkipSizeUpdate(fittingSize: fittingSize, currentFrame: currentFrame) {
            return
        }
        
        lastProcessedSize = fittingSize
        
        if isInitialDisplay {
            isInitialDisplay = false
            let targetPosition = calculateTargetPosition(for: fittingSize)
            let newFrame = NSRect(
                x: targetPosition.x,
                y: targetPosition.y,
                width: fittingSize.width,
                height: fittingSize.height
            )
            window.setFrame(newFrame, display: true)
            return
        }
        
        isResizing = true
        pendingSize = fittingSize
        
        if resizeTimer != nil {
            resizeTimer?.invalidate()
        }
        
        resizeTimer = Timer.scheduledTimer(withTimeInterval: Constants.resizeTimerInterval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.performResize()
            }
        }
    }
    
    func forceUpdateWindowSizeIfNeeded() {
        guard !isResizing else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.forceUpdateWindowSizeIfNeeded()
            }
            return
        }
        
        updateWindowSize()
    }
    
    private func performResize() {
        guard let window = window, let pendingSize = pendingSize else {
            return
        }
        
        let targetPosition = calculateTargetPosition(for: pendingSize)
        let newFrame = NSRect(
            x: window.frame.origin.x,
            y: targetPosition.y,
            width: pendingSize.width,
            height: pendingSize.height
        )
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = Constants.resizeAnimationDuration
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            window.animator().setFrame(newFrame, display: true)
        } completionHandler: {
            self.isResizing = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + Constants.activationDelay) {
                self.forceUpdateWindowSizeIfNeeded()
            }
        }
        
        self.pendingSize = nil
        resizeTimer?.invalidate()
        resizeTimer = nil
    }
    
    private func calculateOptimalPosition() -> CGPoint {
        guard let window = window else {
            return hintPosition
        }
        
        return calculateTargetPosition(for: window.frame.size)
    }
    
    private func calculateTargetPosition(for size: CGSize) -> CGPoint {
        let actualHintHeight = hintHeight ?? QuickEditHintWindowController.hintSize.height
        let hintSize = CGSize(width: QuickEditHintWindowController.hintSize.width, height: actualHintHeight)
        let hintFrame = CGRect(origin: hintPosition, size: hintSize)
        
        guard let screen = hintFrame.findScreen() else {
            return hintPosition
        }
        
        let screenFrame = screen.visibleFrame
        let hintTop = hintPosition.y + actualHintHeight
        let hintBottom = hintPosition.y
        let spaceAbove = screenFrame.maxY - hintTop
        
        let targetY: CGFloat
        
        if spaceAbove >= size.height {
            targetY = hintTop
        } else {
            targetY = hintBottom - size.height
        }
        
        return CGPoint(x: hintPosition.x, y: targetY)
    }
    
    private func checkInitialMousePosition() {
        guard let window = window else { return }
        
        let mouseLocation = NSEvent.mouseLocation
        let windowFrame = window.frame
        let isMouseInside = windowFrame.contains(mouseLocation)
        
        setWindowTransparency(isMouseInside: isMouseInside)
    }
    
    // MARK: - NSWindowDelegate
    
    func windowWillClose(_ notification: Notification) {
        stopEventMonitoring()
        cleanupResizeState()
        window = nil
    }
    
    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
} 
