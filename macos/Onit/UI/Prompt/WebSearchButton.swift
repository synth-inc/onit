import SwiftUI
import Defaults

struct WebSearchButton: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    @State private var showingWebSearchAPIKeyAlert = false

    @Default(.tavilyAPIToken) var tavilyAPIToken
    @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
    @Default(.webSearchEnabled) var webSearchEnabled
    
    var body: some View {
        IconButton(
            icon: .web,
            iconSize: 17,
            action: { toggleWebSearch() },
            inactiveColor:
                webSearchEnabled ? .blue400 :
                !isTavilyAPITokenValidated ? .gray700 :
                nil
        )
        .help(webSearchButtonHelpText)
        .alert("API Token Required", isPresented: $showingWebSearchAPIKeyAlert) {
            Button("Open Settings") {
                appState.setSettingsTab(tab: .webSearch)
                openSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("To use web search, you need to add an web search API token in Settings.")
        }
    }
    
    private var webSearchButtonHelpText: String {
        @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
        if !isTavilyAPITokenValidated {
            return "Add a Tavily API key in Settings > Web Search to enable web search"
        }
        return Defaults[.webSearchEnabled] ? "Web search enabled" : "Enable web search"
    }
    
    private func toggleWebSearch() {
        if !isTavilyAPITokenValidated || tavilyAPIToken.isEmpty {
            AnalyticsManager.Chat.webSearchToggled(isAvailable: false,
                                                   oldValue: webSearchEnabled,
                                                   newValue: webSearchEnabled)
            showingWebSearchAPIKeyAlert = true
            return
        }
        AnalyticsManager.Chat.webSearchToggled(isAvailable: true,
                                               oldValue: webSearchEnabled,
                                               newValue: !webSearchEnabled)
        webSearchEnabled.toggle()
    }
}

#Preview {
    WebSearchButton()
}
