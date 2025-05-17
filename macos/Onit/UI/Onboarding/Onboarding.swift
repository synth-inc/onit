//
//  Onboarding.swift
//  Onit
//
//  Created by Loyd Kim on 5/16/25.
//

import Defaults
import SwiftUI

struct Onboarding: View {
    @Environment(\.appState) var appState
    @Environment(\.windowState) private var windowState
    
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    
    @Default(.panelWidth) var panelWidth
    @Default(.authFlowStatus) var authFlowStatus
    
    @State private var skippedAccessibility: Bool = false
    
    private var shouldShowOnboardingAccessibility: Bool {
        let accessibilityNotGranted = accessibilityPermissionManager.accessibilityPermissionStatus != .granted
        return accessibilityNotGranted && !skippedAccessibility
    }
    
    var body: some View {
        if shouldShowOnboardingAccessibility {
            VStack(spacing: 0) {
                if windowState.showChatView {
                    OnboardingAccessibility(
                        skippedAccessibility: $skippedAccessibility
                    )
                    .transition(.opacity)
                } else {
                    Spacer()
                }
            }
            .frame(width: panelWidth)
            .frame(maxHeight: .infinity)
            // .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black)
            .onAppear {
                if appState.account == nil {
                    authFlowStatus = .showSignUp
                } else {
                    authFlowStatus = .hideAuth
                }
            }
        } else  {
            AuthFlow()
        }
    }
}
