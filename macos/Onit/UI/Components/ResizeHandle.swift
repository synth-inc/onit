//
//  ResizeHandle.swift
//  Onit
//
//  Created by Devin AI on 4/29/25.
//

import SwiftUI

struct ResizeHandle: View {
    var size: CGFloat = 16
    var onDrag: (CGFloat) -> Void
    var onDragEnded: (() -> Void)?
    
    var body: some View {
        ZStack {
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: size, height: size)
        .background(Color.gray600.opacity(0.5))
        .cornerRadius(size/2)
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
