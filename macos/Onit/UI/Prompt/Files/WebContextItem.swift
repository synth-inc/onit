//
//  WebContext.swift
//  Onit
//
//  Created by Loyd Kim on 3/20/25.
//

import SwiftUI
import SwiftSoup

struct WebContextItem: View {
    @Environment(\.windowState) var windowState
    
    private let item: Context
    private let isEditing: Bool
    private let inList: Bool
    private let showContextWindow: () -> Void
    private let removeContextItem: () -> Void
    private let websiteUrl: URL
    private let websiteTitle: String
    
    init(
        item: Context,
        isEditing: Bool,
        inList: Bool,
        showContextWindow: @escaping () -> Void,
        removeContextItem: @escaping () -> Void
    ) {
        self.item = item
        self.isEditing = isEditing
        self.inList = inList
        self.showContextWindow = showContextWindow
        self.removeContextItem = removeContextItem
        
        if case .web(let websiteUrl, let websiteTitle, _) = self.item {
            self.websiteUrl = websiteUrl
            self.websiteTitle = websiteTitle.isEmpty ? (websiteUrl.host() ?? websiteUrl.absoluteString) : websiteTitle
        } else {
            fatalError("Expected a web context item")
        }
    }
    
    var body: some View {
        let websiteUndergoingScrape = windowState.websiteUrlsScrapeQueue.keys.contains(websiteUrl.absoluteString)
        
        TagButton(
            child: websiteUndergoingScrape ? Loader() : favicon,
            text: getCurrentWebsiteTitle(),
            caption: item.fileType,
            action: showContextWindow,
            closeAction: inList ? nil : removeContextItem,
            maxWidth: inList ? 0 : 250,
            fill: inList,
            isTransparent: inList
        )
        .opacity(websiteUndergoingScrape ? 0.5 : 1)
        .disabled(websiteUndergoingScrape)
    }
}

// MARK: - Child Components

extension WebContextItem {
    private var favicon: some View {
        Group {
            if let webpageDomain = websiteUrl.host() {
                AsyncImage(url: URL(string: "https://\(webpageDomain)/favicon.ico")) { image in
                    if let faviconImage = image.image {
                        faviconImage.resizable().frame(width: 16, height: 16)
                    } else {
                        Image(systemName: "globe")
                            .resizable()
                            .frame(width: 16, height: 16)
                    }
                }
            } else {
                Image(systemName: "globe")
                    .resizable()
                    .frame(width: 16, height: 16)
            }
        }
    }
}

// MARK: - Private Functions

extension WebContextItem {
    private func getCurrentWebsiteTitle() -> String {
        let pendingContextList = windowState.getPendingContextList()

        if let updatedWebContext = pendingContextList.first(where: { context in
            if case .web(let contextWebsiteUrl, _, _) = context,
               case .web(let webContextItemWebsiteUrl, _, _) = item
            {
                return contextWebsiteUrl == webContextItemWebsiteUrl
            }
            return false
        }) {
            if case .web(_, let currentWebsiteTitle, _) = updatedWebContext {
                let websiteUrlDomain = websiteUrl.host() ?? websiteUrl.absoluteString
                return currentWebsiteTitle.isEmpty ? websiteUrlDomain : currentWebsiteTitle
            }
        }

        return websiteTitle
    }
}
