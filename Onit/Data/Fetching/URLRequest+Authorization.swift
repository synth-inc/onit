//
//  URLRequest+Authorization.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Foundation

extension URLRequest {
    mutating func addAuthorization(token: String?) {
        guard let token else { return }
        setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
