//
//  ProLimitAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import SwiftUI

struct ProLimitAlert: View {
    @Environment(\.appState) var appState
    
    var body: some View {
        SubscriptionAlert(
            title: "Pro Limit Reached",
            close: { appState.showProLimitAlert = false },
            description: "You have used your 1000 requests for this month.\nYour next renewal is:",
            caption: "💫 25 April 2025"
        )
    }
}
