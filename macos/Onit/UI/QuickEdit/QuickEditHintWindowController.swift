//
//  QuickEditHintWindowController.swift
//  Onit
//
//  Created by Kévin Naudin on 06/16/2025.
//

import AppKit
import SwiftUI

@MainActor
class QuickEditHintWindowController: NSObject, NSWindowDelegate {
    
    // MARK: - QuickEditHintWindow
    
    class QuickEditHintWindow: NSWindow {
        override var canBecomeKey: Bool { false }
        override var canBecomeMain: Bool { false }
    }
    
    // MARK: - Properties
    
    var window: NSWindow?
    
    // MARK: - Functions
    
    func show(at position: CGPoint) {
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
    
    // MARK: - Private functions
    
    private func createWindow(at position: CGPoint) {
        let contentView = QuickEditHintView()
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
        
        let size = NSSize(width: 40, height: 40)
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
        
        let finalPosition = CGPoint(x: position.x - 20, y: position.y - 10)
        
        window.setFrameOrigin(finalPosition)
    }
}
