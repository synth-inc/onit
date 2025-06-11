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
    
    // MARK: - QuickEditWindow
    
    class QuickEditWindow: NSWindow {
        override var canBecomeKey: Bool { true }
        override var canBecomeMain: Bool { false }
    }
    
    // MARK: - MouseTrackingView
    
    class MouseTrackingView: NSView {
        weak var windowController: QuickEditWindowController?
        
        override func updateTrackingAreas() {
            super.updateTrackingAreas()

            trackingAreas.forEach { removeTrackingArea($0) }
            
            let trackingArea = NSTrackingArea(
                rect: bounds,
                options: [.mouseEnteredAndExited, .activeInActiveApp],
                owner: self,
                userInfo: nil
            )
			
            addTrackingArea(trackingArea)
        }
        
        override func mouseEntered(with event: NSEvent) {
            windowController?.setWindowTransparency(isMouseInside: true)
        }
        
        override func mouseExited(with event: NSEvent) {
            windowController?.setWindowTransparency(isMouseInside: false)
        }
        
        override func layout() {
            super.layout()

            DispatchQueue.main.async {
                self.windowController?.updateWindowSize()
            }
        }
    }
    
    // MARK: - Properties
    
    private var window: NSWindow?
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    
    // MARK: - Functions
    
    func show() {
        if window != nil {
            window?.orderFront(nil)
            window?.makeKey()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                self.forceActivation()
            }
            return
        }
        
        createWindow()
    }
    
    func hide() {
        window?.orderOut(nil)
        window = nil
        stopEventMonitoring()
    }
    
    // MARK: - Private functions
    
    private func createWindow() {
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
        window?.center()
        window?.level = .floating
        window?.delegate = self
        window?.isReleasedWhenClosed = false
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
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
		let escapeKeyCode = 53
		
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == escapeKeyCode {
                self?.hide()
                return nil
            }
            return event
        }
        
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            if event.keyCode == escapeKeyCode {
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
        
        let targetAlpha: CGFloat = isMouseInside ? 1.0 : 0.7
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.3
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window.animator().alphaValue = targetAlpha
        }
    }
    
    func updateWindowSize() {
        guard let window = window,
              let contentView = window.contentView else { return }
        
        contentView.needsLayout = true
        contentView.layoutSubtreeIfNeeded()
        
        let fittingSize = contentView.fittingSize
        let currentSize = window.frame.size
        
        if abs(fittingSize.width - currentSize.width) > 1 || 
           abs(fittingSize.height - currentSize.height) > 1 {
            
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.15
                context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
                
                window.animator().setContentSize(fittingSize)
            } completionHandler: {
                window.center()
            }
        }
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
        window = nil
    }
    
    func windowDidResignKey(_ notification: Notification) {
        hide()
    }
} 
