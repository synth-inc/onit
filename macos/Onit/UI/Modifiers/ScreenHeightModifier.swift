//
//  ScreenHeightModifier.swift
//  Onit
//
//  Created by Kévin Naudin on 18/02/2025.
//

import SwiftUI

struct ScreenHeightModifier: ViewModifier {
    @Environment(\.windowState) private var state
    
    @Binding var screenHeight: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                WindowAccessor { window in
                    if let screen = window.screen, screenHeight != screen.visibleFrame.height {
                        screenHeight = screen.visibleFrame.height
                        state.panel?.adjustSize()
                    }
                }
            )
    }
}

struct WindowAccessor: NSViewRepresentable {
    var onUpdate: @MainActor (NSWindow) -> Void

    func makeNSView(context: Self.Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            guard let window = view?.window else { return }
            
            Task { @MainActor in
                onUpdate(window)
                NotificationCenter.default.addObserver(forName: NSWindow.didChangeScreenNotification, object: window, queue: .main) { _ in
                    Task { @MainActor in
                        onUpdate(window)
                    }
                }
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Self.Context) {
        
    }
}

extension View {
    func trackScreenHeight(_ height: Binding<CGFloat>) -> some View {
        self.modifier(ScreenHeightModifier(screenHeight: height))
    }
}
