//
//  MenuIcon.swift
//  Onit
//
//  Created by Benjamin Sage on 10/22/24.
//

import Combine
import SwiftUI
import Defaults

struct MenuIcon: View {
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared

    var body: some View {
        let statusGranted = accessibilityPermissionManager.accessibilityPermissionStatus == .granted
        Image(statusGranted ? .smirk : .untrusted)
            .renderingMode(statusGranted ? .template : .original)
            .animation(.default, value: statusGranted)
    }
}

#if DEBUG
    #Preview {
        MenuIcon()
    }
#endif
