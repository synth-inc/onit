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
    private let isEditing: Bool
    //
    @State private var websiteTitle: String
    @State private var faviconUrl: URL? = nil
    //
    @State private var fetchingWebpageFavicon: Bool = false
    @State private var fetchingWebpageTitle: Bool = false
    @State private var fetchingWebpageContents: Bool = false
    
    var fetchingWebpageData: Bool {
        return fetchingWebpageFavicon || fetchingWebpageTitle || fetchingWebpageContents
    }
    
    init(item: Context, websiteUrl: URL, websiteTitle: String, isEditing: Bool) {
        self.item = item
        self.websiteUrl = websiteUrl
        self.websiteTitle = websiteTitle
        self.isEditing = isEditing
    }
    
    var body: some View {
        let beingScraped = model.websiteUrlsScrapeQueue.keys.contains(websiteUrl.absoluteString)
        
        Button {
            model.showContextWindow(context: item)
        } label: {
            HStack(spacing: 0) {
                if beingScraped {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.5)
                        .frame(width: 16, height: 16)
                } else if let faviconUrl = faviconUrl {
                    AsyncImage(url: faviconUrl) { image in
                        if let faviconImage = image.image {
                            return faviconImage.resizable().frame(width: 16, height: 16)
                        } else {
                            return Image(systemName: "globe")
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
        .onAppear() {
            fetchWebpageFavicon()
        }
    }
    
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
    
    private func fetchWebpageFavicon() {
        if let webpageDomain = websiteUrl.host() {
            faviconUrl = URL(string: "https://\(webpageDomain)/favicon.ico")
        }
    }
}
