//
//  MenuBarLabel.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuBarContent: View {
  @Environment(\.model) var model
  @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared

  var body: some View {
    VStack(spacing: 5) {
      MenuCheckForPermissions()
      MenuOpenOnitButton()
      MenuDivider()
      if featureFlagsManager.accessibility && model.accessibilityPermissionStatus == .granted {
        MenuAppearsInPicker()
        MenuDivider()
      }
      MenuSettings()
      MenuCheckForUpdates()
      MenuHowItWorks()
      MenuDivider()
      MenuQuit()
    }
    .padding(.horizontal, 5)
    .padding(.vertical, 5)
  }
}

#Preview {
  MenuBarContent()
}
