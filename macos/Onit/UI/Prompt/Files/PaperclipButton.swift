//
//  PaperclipButton.swift
//  Onit
//
//  Created by Benjamin Sage on 10/23/24.
//

import SwiftUI
import KeyboardShortcuts

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
                            
                            KeyboardShortcutView(shortcut: KeyboardShortcuts.getShortcut(for: .launchWithAutoContext)?.native)
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
