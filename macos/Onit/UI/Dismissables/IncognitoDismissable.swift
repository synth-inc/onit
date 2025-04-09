//
//  IncognitoDismissable.swift
//  Onit
//
//  Created by Loyd Kim on 4/7/25.
//

import Defaults
import SwiftUI

struct IncognitoDismissable: View {
    @AppStorage("closedIncognitoDismissable") private var closedIncognitoDismissable = false
    @Default(.incognitoModeEnabled) var incognitoModeEnabled
    
    @State var closeHovered: Bool = false
    
    var body: some View {
        if incognitoModeEnabled && !closedIncognitoDismissable {
            VStack(alignment: .leading, spacing: 6) {
                title
                text
            }
            .padding(14)
            .background(.gray900)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .inset(by: 0.5)
                    .stroke(Color(red: 0.28, green: 0.29, blue: 0.31), lineWidth: 1)
            )
            .cornerRadius(16)
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
        }
    }
}


/// Child Components
extension IncognitoDismissable {
    var title: some View {
        HStack {
            Text("Incognito Mode")
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))

            Spacer()
            
            Button {
                closedIncognitoDismissable = true
            } label: {
                Image(.smallCross)
                    .renderingMode(.template)
                    .foregroundStyle(.white)
                    .frame(width: 10, height: 10)
            }
            .opacity(closeHovered ? 0.5 : 1)
            .animation(.easeInOut(duration: 0.15), value: closeHovered)
            .onHover{ isHovering in closeHovered = isHovering}
        }
    }
    
    var text: some View {
        Text("When on, Onit won’t store your chats in history.")
            .foregroundColor(.gray100)
            .font(.system(size: 13, weight: .medium))
    }
}
