//
//  InaccessibleRemoteModelAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import SwiftUI

struct InaccessibleRemoteModelAlert: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    
    var body: some View {
        SubscriptionAlert(
            title: "You don't have access to this model",
            description: "Add the provider API key in settings→",
            descriptionAction: openModelSettings,
            caption: "🚀 Or upgrade to PRO for access to all models!",
            subscriptionText: "Upgrade to Pro!",
            perks: [
                "⭐️ 1000 generations",
                "⭐️ Access to all features",
                "⭐️ Priority support"
            ]
        )
    }
}

// MARK: -  Private Functions

extension InaccessibleRemoteModelAlert {
    private func openModelSettings() {
        NSApp.activate()
        
        if NSApp.isActive {
            appState.setSettingsTab(tab: .models)
            openSettings()
        }
    }
}
