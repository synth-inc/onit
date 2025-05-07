//
//  TetherHintDetails.swift
//  Onit
//
//  Created by Kévin Naudin on 18/04/2025.
//

import SwiftUI

struct TetherHintDetails {
    let tetherWindow: NSWindow
    
    var lastYComputed: CGFloat?
    var showTetherDebounceTimer: Timer? {
        willSet {
            showTetherDebounceTimer?.invalidate()
        }
    }
    let showTetherDebounceDelay: TimeInterval = 0.1
}
