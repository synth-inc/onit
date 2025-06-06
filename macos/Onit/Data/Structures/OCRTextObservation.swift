//
//  OCRTextObservation.swift
//  Onit
//
//  Created by Alex Carmack on 2024.
//

import Foundation
import CoreGraphics

struct OCRTextObservation: Codable, Hashable {
    let text: String
    let bounds: CGRect
    let confidence: Float
    var isFoundInAccessibility: Bool
    var percentageMatched: Int = 0
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(text)
        hasher.combine(bounds.origin.x)
        hasher.combine(bounds.origin.y)
        hasher.combine(bounds.size.width)
        hasher.combine(bounds.size.height)
    }
}
