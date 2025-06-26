import SwiftUI
import Defaults

struct WebSearchButton: View {
    @Environment(\.appState) var appState
    @Default(.webSearchEnabled) var webSearchEnabled
    
    var body: some View {
        IconButton(
            icon: .web,
            iconSize: 17,
            isActive: webSearchEnabled,
            activeColor: .white,
            inactiveColor: webSearchEnabled ? .blue400 : .gray200
        ) {
            toggleWebSearch()
        }
    }
    
    private func toggleWebSearch() {
        AnalyticsManager.Chat.webSearchToggled(oldValue: webSearchEnabled,
                                               newValue: !webSearchEnabled)
        webSearchEnabled.toggle()
    }
}

#Preview {
    WebSearchButton()
}
