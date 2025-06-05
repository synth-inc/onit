//
//  ShortcutsTab.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import KeyboardShortcuts
import SwiftUI
import Defaults

struct ShortcutsTab: View {
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    @Default(.escapeShortcutDisabled) var escapeShortcutDisabled
    
    var body: some View {
        Form {
            Section {
                KeyboardShortcuts.Recorder(
                    "Launch Onit", name: .launch
                )
                .padding()

//                if accessibilityAutoContextEnabled {
//                    KeyboardShortcuts.Recorder(
//                        "Launch Onit with Auto-Context", name: .launchWithAutoContext
//                    )
//                    .padding()
//                }
//
//                KeyboardShortcuts.Recorder(
//                    "New Chat", name: .newChat
//                )
//                .padding()

                KeyboardShortcuts.Recorder(
                    "Switch Local vs Remote", name: .toggleLocalMode
                )
                .padding()
                
                if accessibilityPermissionManager.accessibilityPermissionStatus == .granted && autoContextFromCurrentWindow {
                    KeyboardShortcuts.Recorder(
                        "Add Current Window to Context", name: .addForegroundWindowToContext
                    )
                    .padding()
                }
                
                Toggle("Disable 'ESC' shortcut", isOn: $escapeShortcutDisabled)
                .padding()
            }
        }
        .onChange(of: escapeShortcutDisabled) { _, newValue in
            if newValue {
                // True is disabled. 
                KeyboardShortcuts.disable(.escape)
            } else {
                KeyboardShortcuts.enable(.escape)
            }
        }
        .padding()
    }
}

#Preview {
    ShortcutsTab()
}
