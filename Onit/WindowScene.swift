//
//  WindowScene.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct WindowScene: Scene {
    init() {
        setWindow(.main) {
            $0.level = .floating
            $0.styleMask = [.resizable, .docModalWindow]
            $0.isMovableByWindowBackground = true

            $0.titlebarAppearsTransparent = true
            $0.titleVisibility = .hidden

            $0.backgroundColor = .clear

        }
    }

    var body: some Scene {
        Window("Onit", id: .main) {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 84)
        .keyboardShortcut(.space, modifiers: [.control, .option, .command])
        .handlesExternalEvents(matching: [.launch])
    }
}

struct WindowAccessor: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
