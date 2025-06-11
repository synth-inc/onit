import SwiftUI

struct BottomBanner: View {
    let title: String
    let buttonText: String
    let buttonIcon: String // SF Symbol or asset name
    let buttonAction: () -> Void
    let onClose: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 12) {
                Spacer(minLength: 0)
                HStack {
                    Spacer()
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineSpacing(0)
                    Spacer()
                }
                .padding(.horizontal, 28)
                
                Button(action: buttonAction) {
                    HStack(spacing: 4) {
                        Image(systemName: buttonIcon)
                            .font(.system(size: 20, weight: .medium))
                        Text(buttonText)
                            .font(.system(size: 13, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(red: 88/255, green: 101/255, blue: 242/255)) // #5865f2
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                Spacer(minLength: 0)
            }
            .padding(.vertical, 22)
            .frame(maxWidth: .infinity, maxHeight: 112)
            .background(Color.black)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(red: 223/255, green: 232/255, blue: 255/255).opacity(0.07)),
                alignment: .top
            )
            
            Button(action: onClose) {
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .frame(width: 20, height: 20)
                    
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 6, height: 6)
                        .foregroundColor(.white)
                        .opacity(0.6)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 2)
            .padding(.trailing, 8)
        }
    }
}

#if DEBUG
#Preview {
    BottomBanner(
        title: "Get the latest news & say hi to friends!",
        buttonText: "Join Discord",
        buttonIcon: "bubble.left.and.bubble.right.fill",
        buttonAction: {},
        onClose: {}
    )
    .preferredColorScheme(.dark)
}
#endif
