//
//  PaperclipButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import KeyboardShortcuts
import SwiftUI

struct PaperclipButton: View {
    @Environment(\.model) var model
    @ObservedObject var featureFlagsManager = FeatureFlagManager.shared
    @ObservedObject var notificationsManager = AccessibilityNotificationsManager.shared
    @AppStorage("closedAutocontext") private var closedAutocontext = false

    var accessibilityAutoContextEnabled: Bool {
        featureFlagsManager.accessibilityAutoContext
    }

    var body: some View {
        HStack(spacing: 6) {
            IconButton(
                icon: .paperclip,
                iconSize: 18,
                action: { handleAddContext() },
                tooltipPrompt: accessibilityAutoContextEnabled ? "Add context" : "Upload file"
            )

            if model.pendingContextList.isEmpty {
                if !accessibilityAutoContextEnabled && !closedAutocontext {
                    EnableAutocontextTag()
                } else if accessibilityAutoContextEnabled {
                    Button {
                        handleAddContext()
                    } label: {
                        Text("Add context")
                            .styleText(
                                size: 11,
                                weight: .semibold,
                                color: .gray200
                            )
                    }
                } else {
                    Button {
                        handleAddContext()
                    } label: {

                        Text("Add context")
                            .foregroundStyle(.gray200)
                            .appFont(.medium13)

                    }
                }
            }
        }
        .onAppear {
            resetClosedAutocontext()
        }
    }

    private func resetClosedAutocontext() {
        closedAutocontext = false
    }

    private func handleAddContext() {
        if accessibilityAutoContextEnabled {
            OverlayManager.shared.captureClickPosition()
            OverlayManager.shared.showOverlay(model: model, content: ContextPickerView())
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
