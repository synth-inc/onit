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
    
    // Local states.
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
    
    // Initializing local states.
    init(item: Context, websiteUrl: URL, websiteTitle: String, isEditing: Bool) {
        self.item = item
        self.websiteUrl = websiteUrl
        self.websiteTitle = websiteTitle
        self.isEditing = isEditing
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                model.showAutoContextWindow(context: item)
            } label: {
                HStack(spacing: 0) {
                    if model.websiteUrlsScrapeQueue.keys.contains(websiteUrl.absoluteString) {
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
                        Text(websiteTitle)
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
        }
        .onAppear() {
            fetchWebpageFavicon()
        }
    }
    
    func fetchWebpageFavicon() {
        if let webpageDomain = websiteUrl.host() {
            faviconUrl = URL(string: "https://\(webpageDomain)/favicon.ico")
        }
    }
}
