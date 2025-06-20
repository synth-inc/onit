//
//  QuickEditHintWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 06/16/2025.
//

import AppKit
import SwiftUI

@MainActor
class QuickEditHintWindowController: NSObject, NSWindowDelegate, ObservableObject {
    
    // MARK: - QuickEditHintWindow
    
    class QuickEditHintWindow: NSWindow {
        override var canBecomeKey: Bool { false }
        override var canBecomeMain: Bool { false }
    }
    
    // MARK: - Properties
    
    @Published var currentAppName: String?

    var window: NSWindow?
    var menuWindow: NSWindow?
    
    static let hintSize = CGSize(width: 40, height: 40)
    static let hintOffset = CGPoint(x: -20, y: -10)
    static let menuSize = CGSize(width: 240, height: 120)
    
    // MARK: - Functions
    
    func show(at position: CGPoint, appName: String?) {
        currentAppName = appName
        
        if window != nil {
            updatePosition(position)
            window?.orderFront(nil)
            return
        }
        
        createWindow(at: position)
    }
    
    func hide() {
        window?.orderOut(nil)
        window = nil
    }
    
    // MARK: - Menu Functions
    
    func showMenu(at position: CGPoint) {
        if menuWindow != nil {
            updateMenuPosition(position)
            menuWindow?.orderFront(nil)
            return
        }
        
        createMenuWindow(at: position)
    }
    
    func hideMenu() {
        menuWindow?.orderOut(nil)
        menuWindow = nil
        stopMenuEventMonitoring()
    }
    
    // MARK: - Private functions
    
    private func createWindow(at position: CGPoint) {
        let contentView = QuickEditHintView()
            .environmentObject(self)
        let hostingController = NSHostingController(rootView: contentView)
        
        window = QuickEditHintWindow()
        window?.contentViewController = hostingController
        window?.styleMask = [.borderless]
        window?.isOpaque = false
        window?.backgroundColor = NSColor.clear
        window?.level = .floating
        window?.delegate = self
        window?.isReleasedWhenClosed = false
        window?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window?.hasShadow = false
        
        let size = Self.hintSize
        window?.setContentSize(size)
        
        updatePosition(position)
        
        window?.alphaValue = 0.0
        window?.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window?.animator().alphaValue = 1.0
        }
    }
    
    private func updatePosition(_ position: CGPoint) {
        guard let window = window else { return }
        
        let finalPosition = CGPoint(x: position.x + Self.hintOffset.x,
                                    y: position.y + Self.hintOffset.y)
        
        window.setFrameOrigin(finalPosition)
    }
    
    // MARK: - Private Menu Functions
    
    private func createMenuWindow(at position: CGPoint) {
        let contentView = QuickEditHintMenuView()
            .environmentObject(self)
        let hostingController = NSHostingController(rootView: contentView)
        
        menuWindow = QuickEditHintWindow()
        menuWindow?.contentViewController = hostingController
        menuWindow?.styleMask = [.borderless]
        menuWindow?.isOpaque = false
        menuWindow?.backgroundColor = NSColor.clear
        menuWindow?.level = .floating
        menuWindow?.isReleasedWhenClosed = false
        menuWindow?.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        menuWindow?.hasShadow = true
        
        let size = Self.menuSize
        menuWindow?.setContentSize(size)
        
        updateMenuPosition(position)
        
        menuWindow?.alphaValue = 0.0
        menuWindow?.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            menuWindow?.animator().alphaValue = 1.0
        }
        
        startMenuEventMonitoring()
    }
    
    private func updateMenuPosition(_ position: CGPoint) {
        guard let menuWindow = menuWindow else { return }
        
        let finalPosition = CGPoint(
            x: position.x - 10,
            y: position.y - Self.menuSize.height - 10
        )
        
        menuWindow.setFrameOrigin(finalPosition)
    }
    
    private var menuEventMonitor: Any?
    
    private func startMenuEventMonitoring() {
        menuEventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] event in
            self?.hideMenu()
        }
    }
    
    private func stopMenuEventMonitoring() {
        if let menuEventMonitor = menuEventMonitor {
            NSEvent.removeMonitor(menuEventMonitor)
            self.menuEventMonitor = nil
        }
    }
}
