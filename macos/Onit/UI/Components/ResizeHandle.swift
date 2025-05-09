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
    static let size: CGFloat = 24
    var onDrag: (CGFloat) -> Void
    var onDragEnded: (() -> Void)?
    
    var body: some View {
        ZStack {
            Image(.cornerResize)
                .foregroundColor(.gray300)
                .padding(8)
            // Overlay the non-draggable NSView
            NonDraggableNSView()
                .frame(width: ResizeHandle.size, height: ResizeHandle.size)
                .allowsHitTesting(true)
                .background(Color.clear)
        }
        .frame(width: ResizeHandle.size, height: ResizeHandle.size)
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
