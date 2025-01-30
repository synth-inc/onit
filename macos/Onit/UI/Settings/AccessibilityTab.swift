import SwiftUI

struct AccessibilityTab: View {
    
    struct HighlightHintModeUI: Hashable {
        let mode: HighlightHintMode
        let text: String
    }
    
    private let modes: [HighlightHintModeUI] = [
        .init(mode: .topRight,
              text: "Top-right corner of the screen"),
        .init(mode: .textfield,
              text: "Above the highlighted text"),
    ]
    
    @Environment(\.model) var model
    
    @State private var selectedMode: HighlightHintMode? = Preferences.shared.highlightHintMode
    @State private var showHint: Bool = Preferences.shared.highlightHintMode != nil
    
    var body: some View {
        VStack(spacing: 25) {
            highlightTextView
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 86)
    }
    
    var highlightTextView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Display hint when highlighting text")
                .font(.system(size: 14))
            
            HStack {
                Text("Show hint")
                    .font(.system(size: 13))
                Spacer()
                Toggle("", isOn: $showHint)
                .toggleStyle(.switch)
                .controlSize(.small)
                .onChange(of: showHint, initial: false) { old, new in
                    print("KNA - onChange \(old) \(new)")
                    if new {
                        highlightModeChange(mode: .topRight)
                    } else {
                        highlightModeChange(mode: nil)
                    }
                }
            }
            
            if showHint {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Choose hint position")
                        .font(.system(size: 13))
                    ForEach(modes, id: \.self) { option in
                        HStack {
                            Image(systemName: selectedMode == option.mode ? "largecircle.fill.circle" : "circle")
                                .foregroundColor(.blue)
                            Text(option.text)
                        }
                        .onTapGesture {
                            highlightModeChange(mode: option.mode)
                        }
                    }
                }
            }
        }
    }
    
    private func highlightModeChange(mode: HighlightHintMode?) {
        let preferences = Preferences.shared
        preferences.highlightHintMode = mode
        Preferences.save(preferences)
        
        selectedMode = mode
        
        HighlightHintWindowController.shared.changeMode(mode)
    }
}

#Preview {
    ModelContainerPreview {
        AccessibilityTab()
    }
}
