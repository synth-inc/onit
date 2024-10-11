//
//  GenerationState.swift
//  Onit
//
//  Created by Benjamin Sage on 10/4/24.
//

import Foundation

enum GenerationState: Equatable {
    case idle
    case generating
    case generated(String)
    case error(FetchingError)
}
