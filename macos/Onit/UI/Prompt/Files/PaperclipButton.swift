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
            .tooltip(prompt: featureFlagsManager.flags.accessibility ? "Add context" : "Upload file")

            if model.pendingContextList.isEmpty {
                Button {
                    if featureFlagsManager.flags.accessibility {
                        handleAddContext()
                    } else {
                        model.showFileImporter = true
                    }
                } label: {
                    Text(featureFlagsManager.flags.accessibility ? "Add context" : "Add file")
                        .foregroundStyle(.gray200)
                        .appFont(.medium13)
                }
            }
        }
    }
    
    private func handleAddContext() {
        if featureFlagsManager.flags.accessibility {
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
