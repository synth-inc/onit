import SwiftUI

struct FixedShimmer: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { geo in
                    let gradient = LinearGradient(
                        colors: [.clear, Color.white.opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    Rectangle()
                        .fill(gradient)
                        .rotationEffect(.degrees(30))
                        .offset(x: phase * geo.size.width * 2)
                        .frame(width: geo.size.width * 3, height: geo.size.height)
                        .onAppear {
                            phase = 1
                        }
                        .animation(
                            .linear(duration: 1.2).repeatForever(autoreverses: false),
                            value: phase
                        )
                }
                .mask(content)
            }
    }
}

extension View {
    func fixedShimmer() -> some View {
        modifier(FixedShimmer())
    }
}
