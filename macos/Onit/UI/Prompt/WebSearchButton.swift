import SwiftUI
import Defaults

struct WebSearchButton: View {
    @Environment(\.model) var model
    @State private var showingWebSearchAPIKeyAlert = false
    
    var body: some View {
        @Default(.tavilyAPIToken) var tavilyAPIToken
        @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
        
        return Button(action: toggleWebSearch) {
            Image(systemName: "magnifyingglass")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(model.isWebSearchEnabled ? Color.blue400 : Color.gray200)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .disabled(!isTavilyAPITokenValidated)
        .help(webSearchButtonHelpText)
        .alert("Web Search API Key Required", isPresented: $showingWebSearchAPIKeyAlert) {
            Button("Open Settings") {
                NSWorkspace.shared.open(URL(string: "onit://settings/webSearch")!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please set your Tavily API key in Settings to use web search.")
        }
    }
    
    private var webSearchButtonHelpText: String {
        @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
        
        if !isTavilyAPITokenValidated {
            return "Add a Tavily API key in Settings > Web Search to enable web search"
        }
        return model.isWebSearchEnabled ? "Web search enabled" : "Enable web search"
    }
    
    private func toggleWebSearch() {
        @Default(.tavilyAPIToken) var tavilyAPIToken
        @Default(.isTavilyAPITokenValidated) var isTavilyAPITokenValidated
        
        if !isTavilyAPITokenValidated || tavilyAPIToken.isEmpty {
            showingWebSearchAPIKeyAlert = true
            return
        }
        
        model.isWebSearchEnabled.toggle()
    }
}

#Preview {
    WebSearchButton()
}