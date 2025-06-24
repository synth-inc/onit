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
    
    @Default(.autoContextFromCurrentWindow) var autoContextFromCurrentWindow
    
    var autoContextDisabled: Bool {
        return autoContextFromCurrentWindow && windowState?.foregroundWindow != nil
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
                windowState?.showFileImporter = true
            }
            
            ContextPickerItemView(
                showEmptyIcon: !autoContextFromCurrentWindow,
                imageRes: .stars,
                title: "Current Window",
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
        .background(Color(.gray600))
        .cornerRadius(12)
    }
}

// MARK: - Private Functions

extension ContextPickerView {
    private func getAutoContextTitle() -> String {
        if autoContextDisabled {
            return "Could not determine window"
        } else if !autoContextFromCurrentWindow {
            return "Click to enable"
        } else {
            if let windowState = windowState, let foregroundWindow = windowState.foregroundWindow {
                return WindowHelpers.getWindowName(window: foregroundWindow.element)
            } else {
                return "Current window"
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
