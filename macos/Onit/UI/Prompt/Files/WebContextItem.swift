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
        let beingScraped = windowState.websiteUrlsScrapeQueue.keys.contains(websiteUrl.absoluteString)
        
        Button {
            ContextWindowsManager.shared.showContextWindow(windowState: windowState, context: item)
        } label: {
            HStack(spacing: 0) {
                if beingScraped {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else if let webpageDomain = websiteUrl.host() {
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
                
                Spacer()
                    .frame(width: 4)
                
                HStack(spacing: 2) {
                    Text(getCurrentWebsiteTitle())
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    if let fileType = item.fileType {
                        Text(fileType)
                            .foregroundStyle(.gray200)
                    }
                }
                .appFont(.medium13)
            }
        }
        .opacity(beingScraped ? 0.5 : 1)
        .disabled(beingScraped)
    }
    
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
