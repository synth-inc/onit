//
//  WindowScene.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct WindowScene: Scene {
    var body: some Scene {
        Window("Onit", id: .main) {
            ContentView()
                .background {
//                    WindowAccessor()
                }
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 84)
        .handlesExternalEvents(matching: [.launch])
    }
}

//struct WindowAccessor: NSViewRepresentable {
//    func makeNSView(context: Context) -> NSView {
//        let view = NSView()
//
//        let window = view.window
//        window?.level = .floating
//
//        return view
//    }
//
//    func updateNSView(_ nsView: NSView, context: Context) {}
//}
