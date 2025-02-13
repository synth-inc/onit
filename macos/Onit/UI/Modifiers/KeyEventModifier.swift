//
//  KeyEventModifier.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//

import SwiftUI

struct KeyEventModifier: NSViewRepresentable {
    let perform: (NSEvent) -> Void

    func makeNSView(context: Self.Context) -> NSView {
        let view = NSView()
        view.addSubview(NSEventMonitor(perform: perform))
        return view
    }

    func updateNSView(_ nsView: NSView, context: Self.Context) {}

    private class NSEventMonitor: NSView {
        let perform: (NSEvent) -> Void
        
        init(perform: @escaping (NSEvent) -> Void) {
            self.perform = perform
            super.init(frame: .zero)
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                perform(event)
                return event
            }
        }
        
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    }
}

extension View {
    func onKeyDown(perform: @escaping (NSEvent) -> Void) -> some View {
        self.background(KeyEventModifier(perform: perform))
    }
}
