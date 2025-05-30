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
        
        override func resetCursorRects() {
            addCursorRect(bounds, cursor: .resizeLeftRight)
        }
    }
}

struct ResizeHandle: View {
    var onDrag: (CGFloat) -> Void
    var onDragEnded: (() -> Void)?
    
    @Binding var disableHover: Bool {
        didSet {
            print("RESIZEHANDLE: disableHover changed to: \(disableHover)")
        }
    }
    @State private var isHovering = false
    
    var body: some View {
        ZStack {
            // Overlay the non-draggable NSView
            NonDraggableNSView()
                .allowsHitTesting(true)
                .background(Color.clear)
            
            // Left edge indicator
            Rectangle()
                .fill(Color.white)
                .frame(width: 4)
                .opacity(isHovering ? 0.1 : 0)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
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
            isHovering = hovering && !disableHover
        }
    }
}

#if DEBUG
struct ResizeHandle_Previews: PreviewProvider {
    static var previews: some View {
        ResizeHandle(
            onDrag: { _ in },
            disableHover: .constant(false)
        )
            .previewLayout(.sizeThatFits)
            .padding()
            .background(Color.black)
    }
}
#endif
