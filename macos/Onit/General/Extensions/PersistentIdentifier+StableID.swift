//
//  DiffView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/08/2025.
//

import SwiftData
import Foundation

extension PersistentIdentifier {
    var stableID: String {
        return String(self.hashValue)
    }
}