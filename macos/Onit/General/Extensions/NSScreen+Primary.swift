//
//  NSScreen+Primary.swift
//  Onit
//
//  Created by Kévin Naudin on 16/04/2025.
//

import SwiftUI

extension NSScreen {
    
    static var primary: NSScreen? {
        NSScreen.screens.first { screen in
            screen.frame.origin.x == 0 && screen.frame.origin.y == 0
        }
    }
}
