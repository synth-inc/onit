//
//  Model+Web.swift
//  Onit
//
//  Created by Loyd Kim on 4/1/25.
//

import Foundation

extension OnitModel {
    func addWebsiteUrlScrapeTask(websiteUrl: URL, scrapeTask: WebsiteUrlScrapeTask) {
        websiteUrlsScrapeQueue[websiteUrl.absoluteString] = scrapeTask
    }
    
    func removeWebsiteUrlScrapeTask(websiteUrl: URL) {
        if let scrapeTask = websiteUrlsScrapeQueue[websiteUrl.absoluteString] {
            scrapeTask.cancel()
            websiteUrlsScrapeQueue.removeValue(forKey: websiteUrl.absoluteString)
        }
    }
    
    func scrapeWebsiteUrl(websiteUrl: URL) async {
        if Task.isCancelled { return }

        let websiteScrapTaskStillExists = websiteUrlsScrapeQueue.keys.contains(websiteUrl.absoluteString)
        
        do {
            let webContextItemIndex = getWebContextItemIndex(
                pendingContextList: pendingContextList,
                comparativeWebUrl: websiteUrl
            )

            if let webContextItemIndex = webContextItemIndex {
                if Task.isCancelled { return }
                
                if case .web(
                    let persistedWebsiteUrl,
                    let persistedWebsiteTitle,
                    let persistedWebFileUrl
                ) = pendingContextList[webContextItemIndex] {
                    let websiteAlreadyScraped = persistedWebFileUrl != nil
                    let webContextItemExists = pendingContextList.indices.contains(webContextItemIndex)
                    
                    if !Task.isCancelled && websiteAlreadyScraped && webContextItemExists {
                        pendingContextList[webContextItemIndex] = .web(
                            persistedWebsiteUrl,
                            persistedWebsiteTitle,
                            persistedWebFileUrl
                        )
                    } else {
                        if Task.isCancelled { return }
                        
                        let (webFileUrl, websiteTitle) = try await WebContentFetchService.fetchWebpageContent(
                            websiteUrl: websiteUrl
                        )

                        if Task.isCancelled { return }
                        
                        let webContextItemIndex = getWebContextItemIndex(
                            pendingContextList: pendingContextList,
                            comparativeWebUrl: websiteUrl
                        )
                        
                        if let webContextItemIndex = webContextItemIndex,
                           pendingContextList.indices.contains(webContextItemIndex)
                        {
                            pendingContextList[webContextItemIndex] = .web(
                                persistedWebsiteUrl,
                                websiteTitle,
                                webFileUrl
                            )
                        }
                    }
                    
                    if !Task.isCancelled && websiteScrapTaskStillExists {
                        removeWebsiteUrlScrapeTask(websiteUrl: websiteUrl)
                    }
                }
            }
        } catch is CancellationError {
            if websiteScrapTaskStillExists { removeWebsiteUrlScrapeTask(websiteUrl: websiteUrl) }
        } catch {
            if !Task.isCancelled {
                let webContextItemIndex = getWebContextItemIndex(
                    pendingContextList: pendingContextList,
                    comparativeWebUrl: websiteUrl
                )

                if let webContextItemIndex = webContextItemIndex,
                   pendingContextList.indices.contains(webContextItemIndex)
                {
                    pendingContextList[webContextItemIndex] = .error(websiteUrl, error)
                }
            }

            if websiteScrapTaskStillExists { removeWebsiteUrlScrapeTask(websiteUrl: websiteUrl) }
        }
    }
}
