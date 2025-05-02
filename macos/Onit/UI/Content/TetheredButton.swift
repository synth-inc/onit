//
//  TetheredButton.swift
//  Onit
//
//  Created by Kévin Naudin on 25/03/2025.
//

import Defaults
import SwiftUI

struct TetheredButton: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    @Environment(\.windowState) private var state
    
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    static let width: CGFloat = 19
    static let height: CGFloat = 53
    
    private var fitActiveWindowPrompt: String {
        return "Close Onit"
    }
    
    private var spacerHeight: CGFloat? {
        state.tetheredButtonYPosition
    }
    
    var body: some View {
        VStack {
            if let spacerHeight = spacerHeight {
                Spacer()
                    .frame(height: spacerHeight)
            } else {
                Spacer()
            }
            
            Button(action: {
                state.closePanel()
            }) {
                Image(.smallChevRight)
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .rotationEffect((state.trackedScreen != nil || state.panel == nil || state.panel?.resizedApplication == true) ? .degrees(0) : .degrees(180))
                    .frame(width: Self.width, height: Self.height, alignment: .center)
            }
            
            .background {
                RoundedRectangle(cornerRadius: Self.width / 2)
                    .fill(.black)
            }
            .tooltip(prompt: fitActiveWindowPrompt)
            Spacer()
        }
        .edgesIgnoringSafeArea(.top)
        .frame(maxHeight: .infinity, alignment: .top)
        .zIndex(1)
    }
}

#Preview {
    TetheredButton()
}
