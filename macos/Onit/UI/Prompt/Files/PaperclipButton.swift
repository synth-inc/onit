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
    @Environment(\.windowState) private var windowState
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @AppStorage("closedAutocontext") private var closedAutocontext = false

    @Default(.closedAutoContextTag) var closedAutoContextTag
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    
    private var accessibilityAutoContextEnabled: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    private var showContextMenuBinding: Binding<Bool> {
          Binding(
              get: { windowState?.showContextMenu ?? false },
              set: { windowState?.showContextMenu = $0 }
          )
      }


    var body: some View {
        HStack(spacing: 4) {
            IconButton(
                icon: .paperclip,
                iconSize: 18,
                inactiveColor: Color.S_1,
                tooltipPrompt: accessibilityAutoContextEnabled ? "Add context" : "Upload file"
            ) {
                AnalyticsManager.Chat.paperclipPressed()
                
                if accessibilityAutoContextEnabled && autoContextFromCurrentWindow {
                    windowState?.showContextMenu = true
                } else {
                    handleAddContext()
                }
            }

            if windowState?.pendingContextList.isEmpty ?? true {
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
        .popover(isPresented: showContextMenuBinding) {
            ContextMenu()
        }
    }

    private func resetClosedAutocontext() {
        closedAutocontext = false
    }

    private func handleAddContext() {
        guard let windowState = windowState else { return }
        
        if accessibilityAutoContextEnabled {
            if let panel = windowState.panel {
                if !panel.isKeyWindow {
                    panel.makeKey()
                }
            }
            
            OverlayManager.shared.captureClickPosition()
            
            let view = ContextPickerView()
                .environment(\.appState, appState)
                .environment(\.windowState, windowState)
            
            OverlayManager.shared.showOverlay(content: view)
        } else {
            windowState.showFileImporter = true
        }
    }
}

#if DEBUG
    #Preview {
        PaperclipButton()
    }
#endif
