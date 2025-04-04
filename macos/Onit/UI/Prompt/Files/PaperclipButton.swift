//
//  PaperclipButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import KeyboardShortcuts
import SwiftUI

struct PaperclipButton: View {
    @Environment(\.appState) private var appState
    @Environment(\.windowState) private var state
    @ObservedObject var featureFlagsManager = FeatureFlagManager.shared
    @AppStorage("closedAutocontext") private var closedAutocontext = false

    var accessibilityAutoContextEnabled: Bool {
        featureFlagsManager.accessibilityAutoContext
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
            
            if state.pendingContextList.isEmpty {
                if !accessibilityAutoContextEnabled && !closedAutocontext {
                    EnableAutocontextTag()
                } else if accessibilityAutoContextEnabled {
                    Button {
                        handleAddContext()
                    } label: {
                        HStack(spacing: 0) {
                            Text("Add context (")
                                .foregroundStyle(.gray200)
                                .appFont(.medium13)

                            KeyboardShortcutView(
                                shortcut: KeyboardShortcuts.getShortcut(
                                    for: .launchWithAutoContext)?.native
                            )
                            .foregroundStyle(.gray200)
                            .appFont(.medium13)
                            Text(" for Auto-Context)")
                                .foregroundStyle(.gray200)
                                .appFont(.medium13)
                        }
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
