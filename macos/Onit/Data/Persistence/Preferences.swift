//
//  Preferences.swift
//  Onit
//
//  Created by Benjamin Sage on 10/11/24.
//

import Foundation

struct Preferences: Codable {
    var model: GPTModel?
    var localModel: String? = nil
    var mode: InferenceMode = .remote
    var incognito: Bool = false
}
