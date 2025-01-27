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
    
    var autoContextEnabled: Bool {
        featureFlagsManager.flags.accessibility && notificationsManager.screenResult.others?.isEmpty == false
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
            .tooltip(prompt: autoContextEnabled ? "Add context" : "Upload file")

            if model.pendingContextList.isEmpty {
                Button {
                    handleAddContext()
                } label: {
                    Text(autoContextEnabled ? "Add context" : "Add file")
                        .foregroundStyle(.gray200)
                        .appFont(.medium13)
                }
            }
        }
    }
    
    private func handleAddContext() {
        if autoContextEnabled {
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
