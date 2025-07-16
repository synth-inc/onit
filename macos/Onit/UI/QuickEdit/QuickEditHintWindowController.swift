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

    var window: NSWindow?
    var menuWindow: NSWindow?
    
    static let hintSize = CGSize(width: QuickEditHintView.hintWidth + 2, height: 24)
    static let hintOffset = CGPoint(x: -(QuickEditHintView.hintWidth + 2) * 1.2, y: 0)
    static let menuSize = CGSize(width: 240, height: 120)
    
    private var rightClickMonitor: Any?
    private var menuEventMonitor: Any?
    
    // MARK: - Functions
    
    func show(at position: CGPoint, height: CGFloat) {
        if window != nil {
            updateWindow(at: position, height: height)
            window?.orderFront(nil)
            return
        }
        
        createWindow(at: position, height: height)
    }
    
    func hide() {
        window?.orderOut(nil)
        window = nil
        stopRightClickMonitoring()
    }
    
    // MARK: - Menu Functions
    
    func showMenu() {
        if menuWindow != nil {
            updateMenuPosition()
            menuWindow?.orderFront(nil)
            return
        }
        
        createMenuWindow()
    }
    
    func hideMenu() {
        menuWindow?.orderOut(nil)
        menuWindow = nil
        stopMenuEventMonitoring()
    }
    
    // MARK: - Private functions
    
    private func createWindow(at position: CGPoint, height: CGFloat) {
        let contentView = QuickEditHintView(height: height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped(antialiased: false)
        let hostingController = NSHostingController(rootView: AnyView(contentView))
        hostingController.view.clipsToBounds = false
        
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
        
        updateWindow(at: position, height: height)
        
        window?.alphaValue = 0.0
        window?.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window?.animator().alphaValue = 1.0
        }
        
        startRightClickMonitoring()
    }
    
    private func updateWindow(at position: CGPoint, height: CGFloat) {
        guard let window = window else { return }
        
        let windowSize = calculateWindowSize(for: height)
        
        window.setContentSize(windowSize)
        
        if let hostingController = window.contentViewController as? NSHostingController<AnyView> {
            let newContentView = QuickEditHintView(height: height)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped(antialiased: false)
            hostingController.rootView = AnyView(newContentView)
        }
        
        let iconWidth = QuickEditHintView.hintWidth + (QuickEditHintView.horizontalPadding * 2)
        let adjustedOffset = CGPoint(
            x: Self.hintOffset.x - (windowSize.width - iconWidth) / 2,
            y: Self.hintOffset.y - (windowSize.height - height) / 2
        )
        let finalPosition = CGPoint(x: position.x + adjustedOffset.x,
                                    y: position.y + adjustedOffset.y)
        
        window.setFrameOrigin(finalPosition)
    }
    
    private func calculateWindowSize(for height: CGFloat) -> CGSize {
        let iconWidth = QuickEditHintView.hintWidth
        let horizontalPadding: CGFloat = QuickEditHintView.horizontalPadding * 2
        let verticalPadding: CGFloat = QuickEditHintView.verticalPadding * 2
        
        let realViewWidth = iconWidth + horizontalPadding
        let realViewHeight = height + verticalPadding
        
        return CGSize(
            width: realViewWidth * QuickEditHintView.hoverScale,
            height: realViewHeight * QuickEditHintView.hoverScale
        )
    }
    
    private func startRightClickMonitoring() {
        rightClickMonitor = NSEvent.addLocalMonitorForEvents(matching: [.rightMouseDown]) { [weak self] event in
            guard let self = self, let window = window else { return event }

            let globalClickLocation = NSEvent.mouseLocation
            let windowFrame = window.frame
            
            if windowFrame.contains(globalClickLocation) {
                self.showMenu()
            }

            return event
        }
    }
    
    private func stopRightClickMonitoring() {
        if let rightClickMonitor = rightClickMonitor {
            NSEvent.removeMonitor(rightClickMonitor)
            self.rightClickMonitor = nil
        }
    }
    
    // MARK: - Private Menu Functions
    
    private func createMenuWindow() {
        let contentView = QuickEditHintMenuView()
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
        
        updateMenuPosition()
        
        menuWindow?.alphaValue = 0.0
        menuWindow?.orderFront(nil)
        
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            menuWindow?.animator().alphaValue = 1.0
        }
        
        startMenuEventMonitoring()
    }
    
    private func updateMenuPosition() {
        guard let menuWindow = menuWindow,
              let window = window,
              let hintScreen = window.screen else { return }
        
        let hintFrame = window.frame
        let spaceBelow = hintFrame.minY - hintScreen.visibleFrame.minY
        let finalPosition: CGPoint
        
        if spaceBelow >= Self.menuSize.height {
            finalPosition = CGPoint(
                x: hintFrame.minX,
                y: hintFrame.minY - Self.menuSize.height
            )
        } else {
            finalPosition = CGPoint(
                x: hintFrame.minX,
                y: hintFrame.maxY
            )
        }
        
        menuWindow.setFrameOrigin(finalPosition)
    }
    
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
