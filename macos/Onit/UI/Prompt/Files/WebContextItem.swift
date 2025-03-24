//
//  WebContext.swift
//  Onit
//
//  Created by Loyd Kim on 3/20/25.
//

import Foundation

struct WebContextItem: Codable, Equatable, Hashable {
    let url: URL
    let title: String
    let favicon: URL?
    
    init(url: URL, title: String, favicon: URL?) {
        self.url = url
        self.title = title.isEmpty ? url.host ?? url.absoluteString : title
        self.favicon = favicon
    }
}


enum WebContextFetchStatus {
    case notStarted
    case fetching
    case succeeded
    case failed(Error)
}
