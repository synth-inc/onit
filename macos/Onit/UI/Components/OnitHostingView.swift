//
//  OnitHostingView.swift
//  Onit
//
//  Created by timl on 1/27/25.
//

import SwiftUI

// Custom NSHostingView that accepts first mouse to enable clicking when app is in background
class OnitHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}
