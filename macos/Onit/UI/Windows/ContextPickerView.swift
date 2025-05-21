//
//  ContextPickerView.swift
//  Onit
//
//  Created by Kévin Naudin on 25/01/2025.
//

import SwiftUI

struct ContextPickerView: View {
    @Environment(\.windowState) private var state

    private let currentWindowIconUrl: URL?
    
    init(currentWindowIconUrl: URL? = nil) {
        self.currentWindowIconUrl = currentWindowIconUrl
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                OverlayManager.shared.dismissOverlay()
                state.showFileImporter = true
            }) {
                ContextPickerItemView(
                    imageRes: .file,
                    title: "Upload file",
                    subtitle: "Choose from computer"
                )
            }
            .padding(.top, 6)
            .buttonStyle(.plain)

            Button(action: {
                OverlayManager.shared.dismissOverlay()
                PanelStateCoordinator.shared.fetchWindowContext()
            }) {
                ContextPickerItemView(
                    currentWindowIconUrl: currentWindowIconUrl,
                    imageRes: .stars,
                    title: "AutoContext",
                    subtitle: "Current window"
                )
            }
            .buttonStyle(.plain)
            .foregroundColor(.gray200)
            .padding(.bottom, 6)
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
