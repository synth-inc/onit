//
//  DragModifier.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct DragModifier: ViewModifier {
    @Environment(\.windowState) private var state
    @State var dragging = false

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
                        if let data = item.data {
                            if let image = NSImage(data: data) {
                                state?.addContext(images: [image])
                                return true
                            }
                            return false
                        } else if let url = item.url {
                            state?.addContext(urls: [url])
                            return true
                        }
                        return false
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
