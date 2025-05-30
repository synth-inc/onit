//
//  WebSocketResponse.swift
//  Onit
//
//  Created by Kévin Naudin on 29/05/2025.
//

import Foundation

struct WebSocketResponse: Codable {
    let success: Bool
    let message: String?
    
    init(success: Bool, message: String? = nil) {
        self.success = success
        self.message = message
    }
}
