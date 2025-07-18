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
    
    private let websiteUrl: URL
    private let item: Context
    private let isEditing: Bool
    private let websiteTitle: String
    private let action: () -> Void
    private let removeAction: () -> Void
    
    init(
        item: Context,
        isEditing: Bool,
        action: @escaping () -> Void,
        removeAction: @escaping () -> Void
    ) {
        self.item = item
        self.isEditing = isEditing
        self.action = action
        self.removeAction = removeAction
        
        if case .web(let websiteUrl, let websiteTitle, _) = self.item {
            self.websiteUrl = websiteUrl
            self.websiteTitle = websiteTitle.isEmpty ? (websiteUrl.host() ?? websiteUrl.absoluteString) : websiteTitle
        } else {
            fatalError("Expected a web context item")
        }
    }
    
    var body: some View {
        let websiteUndergoingScrape = windowState?.websiteUrlsScrapeQueue.keys.contains(websiteUrl.absoluteString) ?? false

        ContextTag(
            text: getCurrentWebsiteTitle(),
            textColor: isEditing ? .T_2 : .white,
            background: websiteUndergoingScrape || !isEditing ? .clear : .gray500,
            hoverBackground: isEditing ? .gray400 : .gray600,
            maxWidth: isEditing ? 155 : .infinity,
            isLoading: websiteUndergoingScrape,
            iconView: websiteUndergoingScrape ? LoaderPulse() : favicon,
            caption: item.fileType,
            tooltip: getCurrentWebsiteTitle(),
            action: action,
            removeAction: isEditing ? { removeAction() } : nil
        )
        .disabled(websiteUndergoingScrape)
        .allowsHitTesting(!websiteUndergoingScrape)
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
        guard let pendingContextList = windowState?.getPendingContextList() else {
            return websiteTitle
        }

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
