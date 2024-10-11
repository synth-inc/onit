//
//  GPTModels.swift
//  Onit
//
//  Created by Benjamin Sage on 10/10/24.
//

import Foundation

enum GPTModel: String, CaseIterable, Codable {
    case gpt4mini = "gpt-4o-mini"
    case gpt4 = "gpt-4o"
    case o1mini = "o1-mini"
    case o1Preview = "o1-preview"
}

extension GPTModel: Identifiable {
    var id: RawValue { self.rawValue }
}
