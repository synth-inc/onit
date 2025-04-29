//
//
//

import SwiftUI

struct ResizeHandle: View {
    var size: CGFloat = 16
    var onDrag: (CGFloat) -> Void
    
    var body: some View {
        ZStack {
            Image(systemName: "arrow.left.and.right")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(width: size, height: size)
        .background(Color.gray600.opacity(0.5))
        .cornerRadius(size/2)
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    onDrag(value.translation.width)
                }
        )
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
