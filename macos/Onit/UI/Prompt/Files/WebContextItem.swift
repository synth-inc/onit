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
    @State private var title: String
    @State private var favicon: URL? = nil
    @State private var fetchingWebpageFavicon: Bool = false
    @State private var fetchingWebpageTitle: Bool = false
    @State private var fetchingWebpageContents: Bool = false
    
    var fetchingWebpageData: Bool {
        return fetchingWebpageFavicon || fetchingWebpageTitle || fetchingWebpageContents
    }
    
    // Initializing local states.
    init(item: Context, url: URL, title: String) {
        self.item = item
        self.url = url
        // self.title = title.isEmpty ? url.host ?? url.absoluteString : title
        self.title = title
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
                    else if let favicon = favicon {
                        Image(nsImage: NSImage(contentsOf: favicon) ?? NSImage())
                              .resizable()
                              .frame(width: 16, height: 16)
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
            Task {
                await fetchWebpageFavicon()
                await fetchWebpageTitle()
                await fetchWebpageContents()
            }
        }
    }
    
    func fetchWebpageFavicon() async {
        if let webpageDomain = url.host() {
            // Setting loading state for favicon fetch.
            await MainActor.run {
                fetchingWebpageFavicon = true
            }
            
            // URL that will be used to fetch the favicon of the webpage.
            let faviconUrl = URL(string: "https://\(webpageDomain)/favicon.ico")
            
            // Fetching the favicon image.
            guard let faviconUrl = faviconUrl,
                  let (data, _) = try? await URLSession.shared.data(from: faviconUrl) else {
                    // Removing loading state for favicon fetch.
                    await MainActor.run {
                        fetchingWebpageFavicon = false
                    }
                    return
            }
            
            // Updating favicon state with fetched favicon image.
            do {
                let tempFileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(UUID().uuidString)
                    .appendingPathExtension("ico")
                
                try data.write(to: tempFileURL)
                
                await MainActor.run {
                    self.favicon = tempFileURL
                    fetchingWebpageFavicon = false
                }
            } catch {
                #if DEBUG
                    print("Failed to save favicon: \(error)")
                #endif
                
                // Removing loading state for favicon fetch.
                await MainActor.run {
                    fetchingWebpageFavicon = false
                }
            }
        }
    }
    
    func fetchWebpageTitle() async {
        // Setting loading state for webpage title fetch.
        await MainActor.run {
            fetchingWebpageTitle = true
        }
        
        do {
            // Fetch webpage contents.
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // Check if we got a valid response and, if valid, set `htmlString`.
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
           
           // Update title state.
           await MainActor.run {
               self.title = extractedTitle.isEmpty ? url.host() ?? url.absoluteString : extractedTitle
               fetchingWebpageTitle = false
           }
        } catch {
            #if DEBUG
                print("Failed to fetch webpage title: \(error)")
            #endif
            
            // Removing loading state for webpage title fetch.
            await MainActor.run {
                self.title = url.host() ?? url.absoluteString
                fetchingWebpageTitle = false
            }
        }
    }
    
    func fetchWebpageContents() async {
        do {
            // Setting loading state for webpage contents fetch.
            await MainActor.run {
                fetchingWebpageContents = true
            }
            
            let webContentUrl = try await WebContentFetchService.fetchWebpageContent(from: url)
            
            if let webContextIndex = model.pendingContextList.firstIndex(where: { context in
                switch context {
                case .web (let webContextURL, _):
                    return webContextURL == url
                default:
                    return false
                }
            }) {
                if case .web(let persistedWebUrl, _) = model.pendingContextList[webContextIndex] {
                    model.pendingContextList[webContextIndex] = .web(persistedWebUrl, webContentUrl)
                }
                
                // Removing loading state for webpage contents fetch.
                await MainActor.run {
                    fetchingWebpageContents = false
                }
            } else {
                // Removing loading state for webpage contents fetch.
                await MainActor.run {
                    fetchingWebpageContents = false
                }
            }
        } catch {
            // Removing loading state for webpage contents fetch.
            await MainActor.run {
                fetchingWebpageContents = false
            }
        }
    }
}
