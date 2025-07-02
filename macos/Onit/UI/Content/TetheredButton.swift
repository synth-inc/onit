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
    
    static let width: CGFloat = 19
    static let height: CGFloat = 53
    
    private var fitActiveWindowPrompt: String {
        return "Close Onit"
    }
    
    private var spacerHeight: CGFloat? {
        guard let relativePosition = state.tetheredButtonYRelativePosition else { return nil }
        
        let windowHeight: CGFloat
        if let trackedWindow = state.trackedWindow,
           let frame = trackedWindow.element.getFrame(convertedToGlobalCoordinateSpace: true) {
            windowHeight = frame.height
        } else if let trackedScreen = state.trackedScreen {
            windowHeight = trackedScreen.visibleFrame.height
        } else {
            return nil
        }
        
        return windowHeight * (1.0 - relativePosition) - (Self.height / 2)
    }

    private var arrowRotation: Angle {
        if FeatureFlagManager.shared.usePinnedMode {
            return .degrees(0)
        }

        if state.trackedScreen != nil || state.panel == nil || state.panel?.resizedApplication == true {
            return .degrees(0)
        } else {
            return .degrees(180)
        }
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
                PanelStateCoordinator.shared.closePanel(for: state)
            }) {
                Image(.smallChevRight)
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .rotationEffect(arrowRotation)
                    .frame(width: Self.width, height: Self.height, alignment: .center)
            }
            .background {
                RoundedRectangle(cornerRadius: Self.width / 2)
                    .fill(.black)
            }
            .tooltip(prompt: fitActiveWindowPrompt)
            Spacer()
        }
        .onAppear {
            if let defaultEnvironmentSource = state.defaultEnvironmentSource {
                AnalyticsManager.Technical.defaultWindowState(source: defaultEnvironmentSource)
            }
        }
        .edgesIgnoringSafeArea(.top)
        .frame(maxHeight: .infinity, alignment: .top)
        .zIndex(1)
    }
}

#Preview {
    TetheredButton()
}
