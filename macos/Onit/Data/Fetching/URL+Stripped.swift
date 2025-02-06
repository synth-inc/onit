//
//  URL+Stripped.swift
//  Onit
//
//  Created by Benjamin Sage on 10/29/24.
//

import Foundation

extension URL {
    var stripped: URL {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else {
            return self
        }
        urlComponents.queryItems = nil
        return urlComponents.url ?? self
    }
}
