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
        VStack(alignment: .leading, spacing: 4) {
            ContextPickerItemView(
                imageRes: .file,
                title: "Upload file",
                subtitle: "Choose from computer"
            ) {
                AnalyticsManager.ContextPicker.uploadFilePressed()
                OverlayManager.shared.dismissOverlay()
                state.showFileImporter = true
            }
            
            ContextPickerItemView(
                showEmptyIcon: !autoContextFromCurrentWindow,
                imageRes: .stars,
                title: "Current Window",
                subtitle: getAutoContextTitle(),
                currentWindowBundleUrl: currentWindowBundleUrl
            ) {
                OverlayManager.shared.dismissOverlay()
                
                if autoContextFromCurrentWindow {
                    addWindowToContext()
                } else {
                    enableCurrentWindowSetting()
                }
            }
            .opacity(autoContextDisabled ? 0.6 : 1)
            .allowsHitTesting(!autoContextDisabled)
        }
        .padding(6)
        .background(Color(.gray600))
        .cornerRadius(12)
    }
}

// MARK: - Private Functions

extension ContextPickerView {
    private func getAutoContextTitle() -> String {
        if autoContextDisabled {
            return "Could not determine window"
        } else if autoContextFromCurrentWindow {
            return currentWindowName ?? "Current window"
        } else {
            return "Click to enable"
        }
    }
    
    private func addWindowToContext() {
        AnalyticsManager.ContextPicker.autoContextPressed()
        
        if let windowName = currentWindowName,
           let pid = currentWindowPid
        {
            state.addWindowToContext(
                windowName: windowName,
                pid: pid,
                appBundleUrl: currentWindowBundleUrl
            )
        }
    }
    
    private func enableCurrentWindowSetting() {
        autoContextFromCurrentWindow = true
    }
}
