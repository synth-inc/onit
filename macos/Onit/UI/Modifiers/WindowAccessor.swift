//
//  WindowAccessor.swift
//  Onit
//
//  Created by Kévin Naudin on 18/02/2025.
//

import SwiftUI

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
