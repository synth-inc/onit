//
//  TetheredButton.swift
//  Onit
//
//  Created by Kévin Naudin on 25/03/2025.
//

import Defaults
import SwiftUI

struct TetheredButton: View {
    @Environment(\.model) var model
    @Environment(\.openSettings) var openSettings
    
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    @Default(.fitActiveWindow) var fitActiveWindow
    
    private var isAccessibilityFlagsEnabled: Bool {
        featureFlagsManager.accessibility && featureFlagsManager.accessibilityAutoContext
    }
    
    private var isAccessibilityAuthorized: Bool {
        model.accessibilityPermissionStatus == .granted
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
        
        return fitActiveWindow ? "Detach from active window" : "Fit to active window"
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            Button(action: {
                guard isAccessibilityFlagsEnabled else {
                    model.setSettingsTab(tab: .accessibility)
                    openSettings()
                    return
                }
                guard isAccessibilityAuthorized else {
                    AccessibilityPermissionManager.shared.requestPermission()
                    return
                }
                
                fitActiveWindow.toggle()
            }) {
                Image(.smallChevRight)
                    .renderingMode(.template)
                    .foregroundColor(.white)
                    .rotationEffect(fitActiveWindow ? .degrees(0) : .degrees(180))
                    .frame(width: ContentView.fitActiveWindowWidth, height: 42, alignment: .center)
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
                RoundedRectangle(cornerRadius: ContentView.fitActiveWindowWidth / 2)
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
