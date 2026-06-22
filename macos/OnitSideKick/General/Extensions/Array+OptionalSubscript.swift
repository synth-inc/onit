//
//  Array+OptionalSubscript.swift
//  Onit
//
//  Created by Kévin Naudin on 09/11/2025.
//

import Foundation

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
