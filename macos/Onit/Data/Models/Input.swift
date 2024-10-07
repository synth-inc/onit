//
//  Input.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import Foundation

struct Input: Codable {
    var selectedText: String
    var application: String?
}

// MARK: - Sample

extension Input {
    static let sample = Input(selectedText: "Some input text goes here and looks pretty good", application: "Xcode")
}
