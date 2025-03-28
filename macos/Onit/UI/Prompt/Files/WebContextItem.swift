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
    private let url: URL
    private let isEditing: Bool
    //
    @State private var title: String
    @State private var faviconUrl: URL? = nil
    //
    @State private var fetchingWebpageFavicon: Bool = false
    @State private var fetchingWebpageTitle: Bool = false
    @State private var fetchingWebpageContents: Bool = false
    
    var fetchingWebpageData: Bool {
        return fetchingWebpageFavicon || fetchingWebpageTitle || fetchingWebpageContents
    }
    
    // Initializing local states.
    init(item: Context, url: URL, title: String, isEditing: Bool) {
        self.item = item
        self.url = url
        // self.title = title.isEmpty ? url.host ?? url.absoluteString : title
        self.title = title
        self.isEditing = isEditing
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                model.showAutoContextWindow(context: item)
            } label: {
                HStack(spacing: 0) {
                    if fetchingWebpageData {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(0.5)
                            .frame(width: 16, height: 16)
                    }
                    else if let faviconUrl = faviconUrl {
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
                        Text(title)
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
            
            if isEditing {
                Task {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await fetchWebpageTitle() }
                        group.addTask { await fetchWebpageContents() }
                    }
                }
            }
        }
    }
    
    func fetchWebpageFavicon() {
        if let webpageDomain = url.host() {
            faviconUrl = URL(string: "https://\(webpageDomain)/favicon.ico")
        }
    }
    
    func fetchWebpageTitle() async {
        await MainActor.run {
            fetchingWebpageTitle = true
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode),
                  let htmlString = String(data: data, encoding: .utf8) else {
                      await MainActor.run {
                          fetchingWebpageTitle = false
                      }
                      return
                  }
           
           let parsedWebpage = try SwiftSoup.parse(htmlString)
           let titleElement = try parsedWebpage.select("title").first()
           let extractedTitle = try titleElement?.text() ?? ""
           
           await MainActor.run {
               self.title = extractedTitle.isEmpty ? url.host() ?? url.absoluteString : extractedTitle
               fetchingWebpageTitle = false
           }
        } catch {
            await MainActor.run {
                self.title = url.host() ?? url.absoluteString
                fetchingWebpageTitle = false
            }
        }
    }
    
    func fetchWebpageContents() async {
        do {
            await MainActor.run {
                fetchingWebpageContents = true
            }
            
            if let webContextItemIndex = getWebContextItemIndex(
                pendingContextList: model.pendingContextList,
                comparativeWebUrl: url
            ) {
                if case .web(
                    let persistedWebUrl,
                    let persistedWebContentUrl
                ) = model.pendingContextList[webContextItemIndex] {
                    if persistedWebContentUrl != nil {
                        model.pendingContextList[webContextItemIndex] = .web(persistedWebUrl, persistedWebContentUrl)
                    } else {
                        let webContentUrl = try await WebContentFetchService.fetchWebpageContent(from: url)
                        model.pendingContextList[webContextItemIndex] = .web(persistedWebUrl, webContentUrl)
                    }
                }
            }
            
            await MainActor.run {
                fetchingWebpageContents = false
            }
        } catch {
            await MainActor.run {
                fetchingWebpageContents = false
                
                if let webContextItemIndex = getWebContextItemIndex(
                    pendingContextList: model.pendingContextList,
                    comparativeWebUrl: url
                ) {
                    model.pendingContextList[webContextItemIndex] = .error(url, error)
                }
            }
        }
    }
}
