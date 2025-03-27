//
//  ContextHelpers.swift
//  Onit
//
//  Created by Loyd Kim on 3/27/25.
//

import Foundation

func getWebContextItemIndex(pendingContextList: [Context], comparativeWebUrl: URL) -> Int? {
    if let webContextIndex = pendingContextList.firstIndex(where: { context in
        switch context {
        case .web (let webContextURL, _):
            return webContextURL == comparativeWebUrl
        default:
            return false
        }
    }) {
        return webContextIndex
    } else {
        return nil
    }
}
