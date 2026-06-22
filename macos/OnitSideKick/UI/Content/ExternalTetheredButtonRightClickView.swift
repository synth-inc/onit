//
//  ExternalTetheredButtonRightClickView.swift
//  Onit
//
//  Created by Loyd Kim on 11/3/25.
//

import AppKit
import SwiftUI

struct ExternalTetheredButtonRightClickView<SwiftUIView: View>: NSViewRepresentable {
    // MARK: - Properties
    
    let onRightClick: () -> Void
    let swiftUIView: SwiftUIView

    // MARK: - Initializer
    
    init(
        onRightClick: @escaping () -> Void,
        @ViewBuilder swiftUIView: () -> SwiftUIView
    ) {
        self.onRightClick = onRightClick
        self.swiftUIView = swiftUIView()
    }

    // MARK: - NSViewRepresentable Procotol Conformance
    
    func makeNSView(context: Self.Context) -> RightClickView {
        let hostingView = NSHostingView(rootView: AnyView(self.swiftUIView))

        let rightClickOverlay = RightClickOverlay()
        rightClickOverlay.onRightClick = self.onRightClick
        
        let rightClickView = RightClickView(
            hostingView: hostingView,
            rightClickOverlay: rightClickOverlay /// Transparent overlay that handles capturing isolated right-click events.
        )

        return rightClickView
    }
    
    func updateNSView(_ view: RightClickView, context: Self.Context) {
        view.hostingView.rootView = AnyView(self.swiftUIView)
        view.rightClickOverlay.onRightClick = self.onRightClick
    }
    
    // MARK: - Invisible overlay view that captures the right-click callback
    
    final class RightClickOverlay: NSView {
        var onRightClick: (() -> Void)? = nil

        override func hitTest(_ point: NSPoint) -> NSView? {
            guard let event = NSApp.currentEvent else { return nil }
            
            let rightClickPressed = event.type == .rightMouseDown
            let ctrlLeftClickPressed = event.type == .leftMouseDown && event.modifierFlags.contains(.control)
            let ctrlPressurePressed = event.type == .pressure && event.modifierFlags.contains(.control)
            
            if rightClickPressed || ctrlLeftClickPressed || ctrlPressurePressed {
                return self
            }
            
            return nil
        }

        override func rightMouseDown(with event: NSEvent) {
            self.onRightClick?()
        }
        
        /// Left click
        override func mouseDown(with event: NSEvent) {
            if event.modifierFlags.contains(.control) {
                self.onRightClick?()
            } else {
                super.mouseDown(with: event)
            }
        }
    }
    
    // MARK: - Right Click View
    
    final class RightClickView: NSView {
        let hostingView: NSHostingView<AnyView>
        let rightClickOverlay: RightClickOverlay

        init(
            hostingView: NSHostingView<AnyView>,
            rightClickOverlay: RightClickOverlay
        ) {
            self.hostingView = hostingView
            self.rightClickOverlay = rightClickOverlay
            super.init(frame: .zero)
            self.translatesAutoresizingMaskIntoConstraints = false
            
            self.hostingView.translatesAutoresizingMaskIntoConstraints = false
            self.rightClickOverlay.translatesAutoresizingMaskIntoConstraints = false
            self.rightClickOverlay.wantsLayer = true
            self.rightClickOverlay.layer?.backgroundColor = NSColor.clear.cgColor
            
            self.addSubview(self.hostingView)
            NSLayoutConstraint.activate([
                self.hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
                self.hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
                self.hostingView.topAnchor.constraint(equalTo: topAnchor),
                self.hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
            
            self.addSubview(self.rightClickOverlay)
            NSLayoutConstraint.activate([
                self.rightClickOverlay.leadingAnchor.constraint(equalTo: leadingAnchor),
                self.rightClickOverlay.trailingAnchor.constraint(equalTo: trailingAnchor),
                self.rightClickOverlay.topAnchor.constraint(equalTo: topAnchor),
                self.rightClickOverlay.bottomAnchor.constraint(equalTo: bottomAnchor)
            ])
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { nil }
    }
}
