//
//  DragModifier.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct DragModifier: ViewModifier {
    @Environment(\.model) var model

    @State var dragging = false
    @State private var droppedImage: NSImage = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)!
    @State private var droppedFile: URL?

    var background: Color {
        if dragging {
            Color.white.opacity(0.12)
        } else {
            Color.BG
        }
    }

    func body(content: Content) -> some View {
        content
            .background(background)
            .overlay {
                Color.clear
                    .dropDestination(for: DropItem.self) { items, location in
                        guard let item = items.first else { return false }
                        if let image = item.image {
                            model.addContext(images: [image])
                            return true
                        } else if let url = item.url {
                            model.addContext(urls: [url])
                            return true
                        } else {
                            return false
                        }
                    } isTargeted: { isHovering in
                        dragging = isHovering
                    }
            }
    }
}

extension View {
    func drag() -> some View {
        modifier(DragModifier())
    }
}
