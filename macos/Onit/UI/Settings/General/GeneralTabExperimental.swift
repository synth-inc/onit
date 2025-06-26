//
//  GeneralTabExperimental.swift
//  Onit
//
//  Created by Loyd Kim on 6/26/25.
//

import Defaults
import SwiftUI

struct GeneralTabExperimental: View {
    @Default(.useTextHighlightContext) var useTextHighlightContext
    @Default(.autoAddHighlightedTextToContext) var autoAddHighlightedTextToContext
    
    var body: some View {
        SettingsSection(
            iconSystem: "scissors",
            title: "Experimental"
        ) {
            textHighlight
            autoAddHighlightedTextToContextToggle
        }
    }
}

// MARK: - Child Components

extension GeneralTabExperimental {
    private var textHighlight: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("New Highlighted Text Experience")
                    .font(.system(size: 13))
                
                Spacer()
                
                Toggle("", isOn: $useTextHighlightContext)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                
                SettingInfoButton(
                    title: "New Highlighted Text Experience",
                    description:
                        "When enabled, Onit will use the new fancy UI for highlighted text and will allow to add multiple Highlighted Text items to your conversation.",
                    defaultValue: "off",
                    valueType: "Bool"
                )
            }
            
            Text("New highlighted text experience.")
                .font(.system(size: 12))
                .foregroundStyle(.gray200)
        }
    }
    
    private var autoAddHighlightedTextToContextToggle: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Auto-Add Highlighted Text To Context")
                    .font(.system(size: 13))
                
                Spacer()
                
                Toggle("", isOn: $autoAddHighlightedTextToContext)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
        }
    }
}
