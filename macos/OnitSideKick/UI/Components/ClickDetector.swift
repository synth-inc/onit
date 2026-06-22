//
//  ClickDetector.swift
//  Onit
//
//  Created by Kévin Naudin on 10/31/2025.
//

import SwiftUI

struct ClickDetector: NSViewRepresentable {
    let onRightClick: () -> Void
    let onLeftClick: () -> Void
    
    func makeNSView(context: Self.Context) -> NSView {
        let view = ClickDetectorView()
        
        view.onRightClick = onRightClick
        view.onLeftClick = onLeftClick
        
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Self.Context) {
        if let view = nsView as? ClickDetectorView {
            view.onRightClick = onRightClick
            view.onLeftClick = onLeftClick
        }
    }
    
    private class ClickDetectorView: NSView {
        var onRightClick: (() -> Void)?
        var onLeftClick: (() -> Void)?
        
        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor.clear.cgColor
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override var acceptsFirstResponder: Bool {
            return true
        }
        
        override func mouseDown(with event: NSEvent) {
            onLeftClick?()
            
            super.mouseDown(with: event)
        }
        
        override func rightMouseDown(with event: NSEvent) {
            onRightClick?()
            
            super.rightMouseDown(with: event)
        }
        
        override func hitTest(_ point: NSPoint) -> NSView? {
            let hitView = super.hitTest(point)
            
            return hitView != nil ? self : nil
        }
    }
}
