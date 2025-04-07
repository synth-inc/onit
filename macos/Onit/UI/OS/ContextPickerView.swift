//
//  ContextPickerView.swift
//  Onit
//
//  Created by Kévin Naudin on 25/01/2025.
//

import Defaults
import SwiftUI

struct ContextPickerView: View {
    @Environment(\.model) var model

    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                OverlayManager.shared.dismissOverlay()
                model.showFileImporter = true
            }) {
                ContextPickerItemView(
                    imageRes: .file, title: "Upload file", subtitle: "Choose from computer")
            }
            .padding(.top, 6)
            .buttonStyle(.plain)

            Button(action: {
                if !Defaults[.incognitoModeEnabled] {
                    OverlayManager.shared.dismissOverlay()
                    model.addAutoContext()
                }
            }) {
                ContextPickerItemView(
                    imageRes: .stars,
                    title: "Auto-context",
                    subtitle: Defaults[.incognitoModeEnabled] ? "Disabled in incognito mode" : "Current window activity"
                )
            }
            .buttonStyle(.plain)
            .foregroundColor(.gray200)
            .padding(.bottom, 6)
            .opacity(Defaults[.incognitoModeEnabled] ? 0.5 : 1)
            .disabled(Defaults[.incognitoModeEnabled])
        }
        .background(Color(.gray600))
        .cornerRadius(12)
        .overlay(alignment: .topTrailing) {
            Button(action: {
                OverlayManager.shared.dismissOverlay()
            }) {
                Image(.smallRemove)
                    .renderingMode(.template)
                    .foregroundStyle(.gray200)
            }
            .padding(8)
            .buttonStyle(PlainButtonStyle())
        }
    }
}
