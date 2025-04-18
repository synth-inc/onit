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
    
    private var isAccessibilityFlagsEnabled: Bool {
        featureFlagsManager.accessibility && featureFlagsManager.accessibilityAutoContext
    }
    
    private var isAccessibilityAuthorized: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    private var fitActiveWindowPrompt: String {
        guard featureFlagsManager.accessibility else {
            return "⚠ Enable Auto-Context in Settings"
        }
        guard featureFlagsManager.accessibilityAutoContext else {
            return "⚠ Enable Current Window in Settings"
        }
        guard isAccessibilityAuthorized else {
            return "⚠ Allow Onit application in \"Privacy & Security/Accessibility\""
        }
        
        return "Detach from active window"
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
                guard isAccessibilityFlagsEnabled else {
                    appState.setSettingsTab(tab: .accessibility)
                    openSettings()
                    return
                }
                guard isAccessibilityAuthorized else {
                    AccessibilityPermissionManager.shared.requestPermission()
                    return
                }
                
                state.closePanel()
            }) {
                Image(.smallChevRight)
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .rotationEffect((state.panel == nil || state.panel?.resizedApplication == true) ? .degrees(0) : .degrees(180))
                    .frame(width: Self.width, height: Self.height, alignment: .center)
                    .overlay(
                        Group {
                            if !isAccessibilityFlagsEnabled || !isAccessibilityAuthorized {
                                Rectangle()
                                    .fill(.black)
                                    .frame(height: 2)
                                    .rotationEffect(.degrees(45))
                                    .offset(y: 0)
                                
                                Rectangle()
                                    .fill(.gray200)
                                    .frame(height: 1)
                                    .rotationEffect(.degrees(45))
                                    .offset(y: 0)
                            }
                        }
                    )
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
