//
//  TextBoundingBox.swift
//  Onit
//
//  Created by Timothy Lenardo on 7/8/25.
//

import Foundation

struct TextBoundingBox {
    let text: String
    let boundingBox: CGRect
    let elementRole: String?
    let elementDescription: String?
    
    init(text: String, boundingBox: CGRect, elementRole: String? = nil, elementDescription: String? = nil) {
        self.text = text
        self.boundingBox = boundingBox
        self.elementRole = elementRole
        self.elementDescription = elementDescription
    }
}
