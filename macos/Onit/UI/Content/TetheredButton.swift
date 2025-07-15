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
    
    @State private var isHovering: Bool = false
    
    static let width: CGFloat = 19
    static let height: CGFloat = 53
    
    private var fitActiveWindowPrompt: String {
        return "Close Onit"
    }
    
    private var spacerHeight: CGFloat? {
        guard let state = state else { return nil }
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

        if state?.trackedScreen != nil || state?.panel == nil || state?.panel?.resizedApplication == true {
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
                // Transparent rectangle that fills the entire button area
                RoundedRectangle(cornerRadius: Self.width / 2)
                    .fill(isHovering ? .gray800 : .black)
                    .frame(width: Self.width, height: Self.height)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
                    .overlay {
                        Image(.smallChevRight)
                            .renderingMode(.template)
                            .foregroundColor(.white)
                            .rotationEffect(arrowRotation)
                    }
            }
            .buttonStyle(.plain)
            .background {
                RoundedRectangle(cornerRadius: Self.width / 2)
                    .fill(isHovering ? .gray800 : .black)
                    .animation(.easeInOut(duration: 0.15), value: isHovering)
            }
             .onHover { hovering in
                 isHovering = hovering
                
                 if hovering {
                     TooltipManager.shared.setTooltip(
                         Tooltip(prompt: fitActiveWindowPrompt)
                     )
                 } else {
                     TooltipManager.shared.setTooltip(nil)
                 }
             }
            .overlay {
                TetheredButtonBorder(cornerRadius: Self.width / 2)
                    .stroke(
                        .gray500,
                        lineWidth: 1.5
                    )
            }
            Spacer()
        }
        .edgesIgnoringSafeArea(.top)
        .frame(maxHeight: .infinity, alignment: .top)
        .zIndex(1)
    }
}

struct TetheredButtonBorder: Shape {
    let cornerRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let inset: CGFloat = 0.75 // Half the line width to draw inside
        let midX = rect.midX
        let adjustedCornerRadius = cornerRadius - inset
        let extensionPastHalf: CGFloat = 1.5 // Extra pixels past center for clean connection
        
        // Start from middle of top edge + extension (inset)
        path.move(to: CGPoint(x: midX + extensionPastHalf, y: rect.minY + inset))
        
        // Draw left half of top edge to start of curve
        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + inset))
        
        // Draw top-left curve
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.minY + cornerRadius),
                   radius: adjustedCornerRadius,
                   startAngle: .degrees(270),
                   endAngle: .degrees(180),
                   clockwise: true)
        
        // Draw full left edge
        path.addLine(to: CGPoint(x: rect.minX + inset, y: rect.maxY - cornerRadius))
        
        // Draw bottom-left curve
        path.addArc(center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
                   radius: adjustedCornerRadius,
                   startAngle: .degrees(180),
                   endAngle: .degrees(90),
                   clockwise: true)
        
        // Draw left half of bottom edge to middle + extension
        path.addLine(to: CGPoint(x: midX + extensionPastHalf, y: rect.maxY - inset))
        
        return path
    }
}

#Preview {
    TetheredButton()
}
