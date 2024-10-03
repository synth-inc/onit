//
//  Input.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import Foundation

struct Input {
    var text: String
    var source: String?
}

// MARK: - Sample

extension Input {
    static let sample = Input(text: "Some input text goes here and looks pretty good", source: "Xcode")
}
