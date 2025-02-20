//
//  HighlightedTextSection.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//

import PostHog
import SwiftUI

struct HighlightedTextSection: View {
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    @State private var selectedMode: HighlightHintModeUI = HighlightHintModeUI.from(
        mode: FeatureFlagManager.shared.highlightHintMode)
    
    private let modes: [HighlightHintModeUI] = [
        HighlightHintModeUI.from(mode: .none),
        HighlightHintModeUI.from(mode: .topRight),
        //        HighlightHintModeUI.from(mode: .textfield)
    ]
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Highlighted Text")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle(
                        "",
                        isOn: Binding(
                            get: { featureFlagsManager.accessibilityInput },
                            set: { featureFlagsManager.overrideAccessibilityInput($0) }
                        )
                    )
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    SettingInfoButton(
                        title: "Auto-Context from Highlighted Text",
                        description:
                            "When enabled, Onit will read highlighted text from any application, and add it as context to your conversation. Context is not uploaded until you submit your conversation. In local mode, no context is ever uploaded.",
                        defaultValue: "on",
                        valueType: "Bool"
                    )
                }
                Text("Automatically loads highlighted text as content.")
                    .font(.system(size: 12))
                    .foregroundStyle(.gray200)
            }

            Picker("Choose hint position", selection: $selectedMode) {
                ForEach(modes, id: \.self) { mode in
                    Text(mode.text)
                        .appFont(.medium14)
                        .padding(.vertical, 4)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .pickerStyle(MenuPickerStyle())
            .padding(.vertical, 4)
            .tint(.blue600)
        }
        .onChange(of: selectedMode, initial: false) { old, new in
            highlightModeChange(oldValue: old, newValue: new)
        }
    }
    
    private func highlightModeChange(oldValue: HighlightHintModeUI, newValue: HighlightHintModeUI) {
        FeatureFlagManager.shared.overrideHighlightHintMode(newValue.mode)
        HighlightHintWindowController.shared.changeMode(newValue.mode)

        let eventProperties: [String: Any] = [
            "old": oldValue.mode,
            "new": newValue.mode,
        ]

        PostHogSDK.shared.capture("highlight_hint_mode_change", properties: eventProperties)
    }
    
    struct HighlightHintModeUI: Identifiable, Hashable, Equatable {
        let mode: HighlightHintMode
        let text: String

        var id: String { text }

        static func from(mode: HighlightHintMode) -> Self {
            let text: String

            switch mode {
            case .topRight:
                text = "Top-right corner of the screen"
            case .textfield:
                text = "Above the highlighted text"
            case .none:
                text = "No hint"
            }

            return .init(mode: mode, text: text)
        }

        static func == (lhs: HighlightHintModeUI, rhs: HighlightHintModeUI) -> Bool {
            return lhs.mode == rhs.mode
        }
    }
}

#Preview {
    HighlightedTextSection()
}
