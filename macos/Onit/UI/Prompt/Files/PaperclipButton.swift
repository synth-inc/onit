//
//  PaperclipButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI

struct PaperclipButton: View {
    @Environment(\.model) var model
    @ObservedObject var featureFlagsManager = FeatureFlagManager.shared
    @ObservedObject var notificationsManager = AccessibilityNotificationsManager.shared
    
    var accessibilityAutoContextEnabled: Bool {
        featureFlagsManager.flags.accessibility && featureFlagsManager.flags.accessibilityAutoContext
    }

    var body: some View {
        HStack(spacing: 6) {
            Button {
                handleAddContext()
            } label: {
                Image(.paperclip)
                    .resizable()
                    .frame(width: 16, height: 16)
                    .padding(3)
            }
            .tooltip(prompt: accessibilityAutoContextEnabled ? "Add context" : "Upload file")

            if model.pendingContextList.isEmpty {
                Button {
                    handleAddContext()
                } label: {
                    Text(accessibilityAutoContextEnabled ? "Add context" : "Add file")
                        .foregroundStyle(.gray200)
                        .appFont(.medium13)
                }
            }
        }
    }
    
    private func handleAddContext() {
        if accessibilityAutoContextEnabled {
            model.showContextPickerOverlay()
        } else {
            model.showFileImporter = true
        }
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        PaperclipButton()
    }
}
#endif
