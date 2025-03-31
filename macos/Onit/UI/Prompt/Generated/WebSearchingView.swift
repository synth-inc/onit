import SwiftUI

struct WebSearchingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundColor(.blue400)
                
                Text("Searching the web...")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray800)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                LinearGradient(
                                    gradient: Gradient(colors: [.blue400.opacity(isAnimating ? 0.8 : 0.2), .blue400.opacity(isAnimating ? 0.2 : 0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
            .onAppear {
                withAnimation(Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .padding(.horizontal, 16)
    }
}

#Preview {
    WebSearchingView()
        .frame(maxWidth: .infinity)
        .background(Color.black)
}