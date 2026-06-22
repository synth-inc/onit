//
//  DeleteAccountButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/30/25.
//

import SwiftUI

struct DeleteAccountButton: View {
    @State private var showDeleteAccountAlert: Bool = false
    @State private var accountDeleteErrorMessage: String? = nil

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            SimpleButton(
                text: String.localized("Delete account"),
                textColor: Color.red,
                action: {
                    AnalyticsManager.AccountEvents.deletePressed()
                    showDeleteAccountAlert = true
                },
                background: Color.redDisabledHover
            )
            .sheet(isPresented: $showDeleteAccountAlert) {
                DeleteAccountConfirmationAlert(
                    show: $showDeleteAccountAlert,
                    accountDeleteErrorMessage: $accountDeleteErrorMessage
                )
            }

            if let errorMessage = accountDeleteErrorMessage {
                Text(errorMessage)
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: Color.red500
                    )
            }
        }
    }
}
