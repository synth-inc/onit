//
//  OCRMessage.swift
//  Onit
//
//  Created by Kévin Naudin on 29/05/2025.
//

import Foundation

struct OCRMessage: Codable {
    let confidence: Int
    let extractedText: String
    let pageTitle: String
    let pageUrl: String
}
