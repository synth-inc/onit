//
//  WebSocketMessage.swift
//  Onit
//
//  Created by Kévin Naudin on 29/05/2025.
//

import Foundation

struct WebSocketMessage: Codable {
    let ocrMessage: OCRMessage
    let htmlToTextMessage: HtmlToTextMessage
}
