//
//  MenuCheckForPermissions.swift
//  Onit
//
//  Created by Benjamin Sage on 10/22/24.
//

import SwiftUI

struct MenuCheckForPermissions: View {
    @Environment(\.model) var model
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

    let circleHeight: CGFloat = 5
    let link = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

    var body: some View {
        if featureFlagsManager.accessibility && model.accessibilityPermissionStatus != .granted {
            permissionsRow
            MenuDivider()
        }
    }

    var permissionsRow: some View {
        MenuBarRow {
            if let url = URL(string: link) {
                NSWorkspace.shared.open(url)
            }
        } leading: {
            HStack(spacing: 9) {
                Circle()
                    .fill(Color(.displayP3, red: 1, green: 0, blue: 0))
                    .frame(width: circleHeight, height: circleHeight)
                Text("Allow access...")
            }
            .padding(.horizontal, 10)
        }
    }
}

#Preview {
    MenuCheckForPermissions()
}
