//
//  HTTPMethod.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation

public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

extension HTTPMethod {
    var requiresContentType: Bool {
        [.post, .put, .patch].contains(self)
    }
}
