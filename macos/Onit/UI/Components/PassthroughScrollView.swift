//
//  PassthroughScrollView.swift
//  Onit
//
//  Created by Kévin Naudin on 07/03/2025.
//

import SwiftUI

class PassthroughScrollView: NSScrollView {
    override func scrollWheel(with event: NSEvent) {
        nextResponder?.scrollWheel(with: event)
    }
}
