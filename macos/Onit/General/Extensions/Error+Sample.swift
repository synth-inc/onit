//
//  Error+Sample.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

extension Error where Self == NSError {
    static func sample(_ message: String) -> Error {
        NSError(domain: message, code: 0)
    }
}
