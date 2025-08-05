//
//  ResizeHandle.swift
//  Onit
//
//  Created by Devin AI on 4/29/25.
//

import SwiftUI

// NSViewRepresentable that prevents mouseDown from moving the window
struct NonDraggableNSView: NSViewRepresentable {
    
    func makeNSView(context: Self.Context) -> NSView {
        let view = NonDraggableView()
        return view
    }
    func updateNSView(_ nsView: NSView, context: Self.Context) {
    }

    class NonDraggableView: NSView {
        override var mouseDownCanMoveWindow: Bool { false }
    }
}

struct ResizeHandle: View {
    var onDrag: (CGFloat) -> Void
    var onDragEnded: (() -> Void)?
    @State private var isHovered = false
    
    var body: some View {
        ZStack {
            // Overlay the non-draggable NSView
            NonDraggableNSView()
                .allowsHitTesting(true)
                .background(Color.clear)
        }
        .background(
            RoundedCorners(radius: 14, corners: .bottomLeft)
                .fill(Color.T_1)
                .opacity(isHovered ? 0.2 : 0)
        )
        .clipped()
        .highPriorityGesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .local)
                .onChanged { value in
                    onDrag(value.translation.width)
                }
                .onEnded { _ in
                    onDragEnded?()
                }
        )
        .contentShape(Rectangle()) // Ensure the entire area is tappable
        .allowsHitTesting(true) // Make sure the view intercepts all events
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

#if DEBUG
struct ResizeHandle_Previews: PreviewProvider {
    static var previews: some View {
        ResizeHandle(onDrag: { _ in })
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
    }
}
#endif
