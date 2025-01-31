import PostHog
import SwiftUI

struct AccessibilityTab: View {
    
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
    
    private let modes: [HighlightHintModeUI] = [
        HighlightHintModeUI.from(mode: .none),
        HighlightHintModeUI.from(mode: .topRight),
        HighlightHintModeUI.from(mode: .textfield)
    ]
    
    @Environment(\.model) var model
    
    @State private var selectedMode: HighlightHintModeUI = HighlightHintModeUI.from(mode: FeatureFlagManager.shared.highlightHintMode)
    
    var body: some View {
        VStack(spacing: 25) {
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
            .padding(.bottom, 5)
            .padding(.leading, 5)
            .tint(.blue600)
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 86)
        .onChange(of: selectedMode, initial: false) { old, new in
            highlightModeChange(oldValue: old, newValue: new)
        }
    }
    
    private func highlightModeChange(oldValue: HighlightHintModeUI, newValue: HighlightHintModeUI) {
        FeatureFlagManager.shared.overrideHighlightHintMode(newValue.mode)
        HighlightHintWindowController.shared.changeMode(newValue.mode)
        
        let eventProperties: [String: Any] = [
            "old": oldValue.mode,
            "new": newValue.mode
        ]
        
        PostHogSDK.shared.capture("highlight_hint_mode_change", properties: eventProperties)
    }
}

#Preview {
    ModelContainerPreview {
        AccessibilityTab()
    }
}
