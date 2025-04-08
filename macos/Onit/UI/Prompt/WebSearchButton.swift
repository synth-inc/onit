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
        return Button(action: toggleWebSearch) {
            Image(.web)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(webSearchEnabled ? Color.blue400 : (isTavilyAPITokenValidated ? Color.gray200 : Color.gray700))
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
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
            showingWebSearchAPIKeyAlert = true
            return
        }
        webSearchEnabled.toggle()
    }
}

#Preview {
    WebSearchButton()
}
