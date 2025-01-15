//
//  CaptureNSViewModifier.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import SwiftUI
import AppKit

struct CaptureNSView: ViewModifier {
    let callback: (NSView) -> Void

    func body(content: Content) -> some View {
        content.background {
            CaptureNSViewRepresentable(onReceiveNSView: callback)
                .frame(width: 0, height: 0)
            }
    }
}

struct CaptureNSViewRepresentable: NSViewRepresentable {
    let onReceiveNSView: (NSView) -> Void

    func makeNSView(context: NSViewRepresentableContext<CaptureNSViewRepresentable>) -> NSView {
        let nsView = NSView(frame: .zero)

        DispatchQueue.main.async {
            self.onReceiveNSView(nsView)
        }

        return nsView
    }

    func updateNSView(_ nsView: NSView, context: NSViewRepresentableContext<CaptureNSViewRepresentable>) {
        // No update needed
    }
}

extension View {
    func captureNSView(_ callback: @escaping (NSView) -> Void) -> some View {
        self.modifier(CaptureNSView(callback: callback))
    }
}
