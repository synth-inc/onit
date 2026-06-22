//
//  ContextPickerView.swift
//  Onit
//
//  Created by Kévin Naudin on 25/01/2025.
//

import Defaults
import SwiftUI

struct ContextPickerView: View {
    @Environment(\.windowState) private var windowState
    @ObservedObject private var localization = LocalizationManager.shared

    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    
    var autoContextDisabled: Bool {
        return autoContextFromCurrentWindow && windowState?.foregroundWindow != nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ContextPickerItemView(
                imageRes: .file,
                title: String.localized("Upload file", table: "Sidekick"),
                subtitle: String.localized("Choose from computer", table: "Sidekick")
            ) {
                AnalyticsManager.ContextPicker.uploadFilePressed()
                OverlayManager.shared.dismissOverlay()
                windowState?.showFileImporter = true
            }
            
            ContextPickerItemView(
                showEmptyIcon: !autoContextFromCurrentWindow,
                imageRes: .stars,
                title: String.localized("Current Window", table: "Sidekick"),
                subtitle: getAutoContextTitle()
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
        .background(Color.S_6)
        .cornerRadius(12)
        .id(localization.currentLanguage)
    }
}

// MARK: - Private Functions

extension ContextPickerView {
    private func getAutoContextTitle() -> String {
        if autoContextDisabled {
            return String.localized("Could not determine window", table: "Sidekick")
        } else if !autoContextFromCurrentWindow {
            return String.localized("Click to enable", table: "Sidekick")
        } else {
            if let foregroundWindow = windowState?.foregroundWindow {
                return WindowHelpers.getWindowName(window: foregroundWindow.element)
            } else {
                return String.localized("Current window", table: "Sidekick")
            }
        }
    }
    
    private func addWindowToContext() {
        AnalyticsManager.ContextPicker.autoContextPressed()
        
        guard let windowState = windowState else { return }
        
        if let foregroundWindow = windowState.foregroundWindow {
            windowState.addWindowToContext(
                window: foregroundWindow.element
            )
        }
    }
    
    private func enableCurrentWindowSetting() {
        autoContextFromCurrentWindow = true
    }
}
