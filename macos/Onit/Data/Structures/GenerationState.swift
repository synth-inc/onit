//
//  GenerationState.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

enum GenerationState: Equatable, Codable {
    case starting
    case generating
    case streaming
    case done
}
