//
//  MenuIcon.swift
//  Onit
//
//  Created by Benjamin Sage on 10/22/24.
//

import SwiftUI
import Combine

struct MenuIcon: View {
    @Environment(\.model) var model
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    var body: some View {
        if featureFlagsManager.flags.accessibility {
            let statusGranted = model.accessibilityPermissionStatus == .granted
            Image(statusGranted ? .smirk : .untrusted)
                .renderingMode(statusGranted ? .template : .original)
                .animation(.default, value: statusGranted)
        } else {
            Image(.smirk)
                .renderingMode(.template)
                .animation(.default, value: true)
        }
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        MenuIcon()
    }
}
#endif
