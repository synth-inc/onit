//
//  WebContext.swift
//  Onit
//
//  Created by Loyd Kim on 3/20/25.
//

import SwiftUI
import SwiftSoup

struct WebContextItem: View {
    @Environment(\.model) var model
    
    private let item: Context
    private let websiteUrl: URL
    private let websiteTitle: String
    private let isEditing: Bool
    
    init(item: Context, isEditing: Bool) {
        self.item = item
        
        if case .web(let websiteUrl, let websiteTitle, _) = self.item {
            self.websiteUrl = websiteUrl
            self.websiteTitle = websiteTitle.isEmpty ? (websiteUrl.host() ?? websiteUrl.absoluteString) : websiteTitle
        } else {
            fatalError("Expected a web context item")
        }
        
        self.isEditing = isEditing
    }
    
    var body: some View {
        let websiteUndergoingScrape = model.websiteUrlsScrapeQueue.keys.contains(websiteUrl.absoluteString)
        
        TagButton(
            child: websiteUndergoingScrape ? Loader() : favicon,
            text: getCurrentWebsiteTitle(),
            caption: item.fileType,
            action: { model.showContextWindow(context: item) },
            closeAction: { model.deleteContextItem(item: item) },
            maxWidth: 250
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
        let pendingContextList = model.getPendingContextList()

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
