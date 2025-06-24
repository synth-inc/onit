import SwiftUI
import Defaults

struct WebSearchButton: View {
    @Default(.tavilyAPIToken) var tavilyAPIToken
    @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
    @Default(.webSearchEnabled) var webSearchEnabled
    
    var body: some View {
        IconButton(
            icon: .web,
            iconSize: 17,
            action: { toggleWebSearch() },
            isActive: webSearchEnabled,
            activeColor: .white,
            inactiveColor: webSearchEnabled ? .blue400 : nil
        )
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
