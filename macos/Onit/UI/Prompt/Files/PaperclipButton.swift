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
    
    private let currentWindowIcon: NSImage?
    
    init(currentWindowIcon: NSImage? = nil) {
        self.currentWindowIcon = currentWindowIcon
    }
    
    var accessibilityAutoContextEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }

    var body: some View {
        HStack(spacing: 6) {
            IconButton(
                icon: .paperclip,
                iconSize: 18,
                action: { handleAddContext() },
                tooltipPrompt: accessibilityAutoContextEnabled ? "Add context" : "Upload file"
            )

            if state.pendingContextList.isEmpty {
                if !accessibilityAutoContextEnabled && !closedAutoContextTag {
                    EnableAutocontextTag()
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
            let view = ContextPickerView(currentWindowIcon: currentWindowIcon)
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
