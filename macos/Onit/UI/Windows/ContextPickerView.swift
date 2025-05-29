//
//  ContextPickerView.swift
//  Onit
//
//  Created by Kévin Naudin on 25/01/2025.
//

import Defaults
import SwiftUI

struct ContextPickerView: View {
    @Environment(\.windowState) private var state
    
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow

    private let currentWindowName: String?
    private let currentWindowBundleUrl: URL?
    private let currentWindowPid: pid_t?
    
    init(
        currentWindowBundleUrl: URL? = nil,
        currentWindowName: String?,
        currentWindowPid: pid_t?
    ) {
        self.currentWindowBundleUrl = currentWindowBundleUrl
        self.currentWindowName = currentWindowName
        self.currentWindowPid = currentWindowPid
    }
    
    var autoContextDisabled: Bool {
        return autoContextFromCurrentWindow && (currentWindowName == nil || currentWindowPid == nil)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Button(action: {
                AnalyticsManager.ContextPicker.uploadFilePressed()
                OverlayManager.shared.dismissOverlay()
                state.showFileImporter = true
            }) {
                ContextPickerItemView(
                    imageRes: .file,
                    title: "Upload file",
                    subtitle: "Choose from computer"
                )
            }
            .padding(.top, 6)
            .buttonStyle(.plain)

            Button(action: {
                OverlayManager.shared.dismissOverlay()
                
                if autoContextFromCurrentWindow {
                    addAutoContext()
                } else {
                    enableCurrentWindowSetting()
                }
            }) {
                ContextPickerItemView(
                    showEmptyIcon: !autoContextFromCurrentWindow,
                    imageRes: .stars,
                    title: autoContextFromCurrentWindow ? "AutoContext" : "Current Window",
                    subtitle: autoContextFromCurrentWindow ? "Current window" : "Click to enable",
                    currentWindowBundleUrl: currentWindowBundleUrl
                )
            }
            .buttonStyle(.plain)
            .foregroundColor(.gray200)
            .padding(.bottom, 6)
            .opacity(autoContextDisabled ? 0.6 : 1)
            .allowsHitTesting(!autoContextDisabled)
        }
        .background(Color(.gray600))
        .cornerRadius(12)
        .overlay(alignment: .topTrailing) {
            Button(action: {
                OverlayManager.shared.dismissOverlay()
            }) {
                Image(.smallRemove)
                    .renderingMode(.template)
                    .foregroundStyle(.gray200)
            }
            .padding(8)
            .buttonStyle(PlainButtonStyle())
        }
    }
}

// MARK: - Private Functions

extension ContextPickerView {
    private func addAutoContext() {
        AnalyticsManager.ContextPicker.autoContextPressed()
        
        if let windowName = currentWindowName,
           let pid = currentWindowPid,
           let focusedWindow = pid.firstMainWindow
        {
            state.addAutoContextTasks[windowName]?.cancel()
            
            state.addAutoContextTasks[windowName] = Task {
                let _ = AccessibilityNotificationsManager.shared.windowsManager.append(focusedWindow, pid: pid)
                AccessibilityNotificationsManager.shared.fetchAutoContext(pid: pid, state: state)
            }
        }
    }
    
    private func enableCurrentWindowSetting() {
        autoContextFromCurrentWindow = true
    }
}
