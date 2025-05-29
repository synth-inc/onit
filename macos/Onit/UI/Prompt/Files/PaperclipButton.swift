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
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    
    private let currentWindowBundleUrl: URL?
    private let currentWindowName: String?
    private let currentWindowPid: pid_t?
    
    init(
        currentWindowBundleUrl: URL? = nil,
        currentWindowName: String? = nil,
        currentWindowPid: pid_t? = nil,
    ) {
        self.currentWindowBundleUrl = currentWindowBundleUrl
        self.currentWindowName = currentWindowName
        self.currentWindowPid = currentWindowPid
    }
    
    var accessibilityAutoContextEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }

    var body: some View {
        HStack(spacing: 4) {
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
                }
            }
            
            if !autoContextFromCurrentWindow {
                Button {
                    handleAddContext()
                } label: {
                    Text("Add context")
                        .styleText(
                            size: 13,
                            weight: .medium,
                            color: .gray200
                        )
                }
            }
        }
        .padding(.trailing, 4)
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
            
            let view = ContextPickerView(
                currentWindowBundleUrl: currentWindowBundleUrl,
                currentWindowName: currentWindowName,
                currentWindowPid: currentWindowPid
            )
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
