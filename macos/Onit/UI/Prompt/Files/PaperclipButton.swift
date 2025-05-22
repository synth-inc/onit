//
//  PaperclipButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import KeyboardShortcuts
import SwiftUI
import Defaults

struct PaperclipButton: View {
    @Environment(\.appState) private var appState
    @Environment(\.windowState) private var state
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    @AppStorage("closedAutocontext") private var closedAutocontext = false

    @Default(.closedAutoContextTag) var closedAutoContextTag
    
    var accessibilityAutoContextEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }

    var body: some View {
        HStack(spacing: 6) {
            IconButton(
                icon: .paperclip,
                iconSize: 18,
                action: {
                    AnalyticsManager.Chat.paperclipPressed()
                    handleAddContext()
                },
                tooltipPrompt: accessibilityAutoContextEnabled ? "Add context" : "Upload file"
            )

            if state.pendingContextList.isEmpty {
                if !accessibilityAutoContextEnabled && !closedAutoContextTag {
                    EnableAutocontextTag()
                } else if accessibilityAutoContextEnabled {
                    Button {
                        AnalyticsManager.Chat.addContextPressed()
                        handleAddContext()
                    } label: {
                        Text("Add context")
                            .styleText(
                                size: 13,
                                weight: .medium,
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
            if let panel = state.panel {
                if !panel.isKeyWindow {
                    panel.makeKey()
                }
            }
            OverlayManager.shared.captureClickPosition()
            let view = ContextPickerView()
                .environment(\.appState, appState)
                .environment(\.windowState, state)
            OverlayManager.shared.showOverlay(content: view)
        } else {
            state.showFileImporter = true
        }
    }
}

#if DEBUG
    #Preview {
        PaperclipButton()
    }
#endif
