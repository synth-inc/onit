//
//  LoadingView.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import PostHog
import SwiftUI

struct LoadingView: View {
    @State private var isLoading: Bool = true
    @State private var message: String = "Loading librairies..."
    
    let onLoadingFinished: () -> Void
    
    let featureFlagsReceivedPub = NotificationCenter.default.publisher(for: PostHogSDK.didReceiveFeatureFlags)

    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)

            Text(message)
                .font(.headline)
                .foregroundColor(.gray)
        }
        .padding()
        .onAppear { initializeLibraries() }
        .onReceive(featureFlagsReceivedPub) { _ in featureFlagsReceived() }
    }

    /** Initialize all libraries and wait for some async responses */
    private func initializeLibraries() {
        FeatureFlagManager.shared.configure()
    }
    
    /**
     * On feature flags received event :
     * - Initialize stuff depending on feature flag
     * - Notify the app that the loading is finished
     */
    private func featureFlagsReceived() {
        if FeatureFlagManager.shared.isAccessibilityEnabled() {
            initializeAccessibility()
        }
        
        onLoadingFinished()
    }
    
    /** Initialize the Accessibility listeners */
    private func initializeAccessibility() {
        #if !targetEnvironment(simulator)
        
        AccessibilityPermissionManager.shared.requestPermission()
        
        #endif
    }
}

#Preview {
    LoadingView { }
}
