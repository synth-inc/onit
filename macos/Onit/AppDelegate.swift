//
//  AppDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
  @MainActor
  func applicationDidFinishLaunching(_ notification: Notification) {
    AnalyticsManager.shared.configure()

    // This is helpful for debugging the new user experience, but should never be committed!
    //        if let appDomain = Bundle.main.bundleIdentifier {
    //            UserDefaults.standard.removePersistentDomain(forName: appDomain)
    //            UserDefaults.standard.synchronize()
    //        }
  }

  @MainActor
  func applicationWillTerminate(_ notification: Notification) {
    AnalyticsManager.shared.capture("app_quit")
  }
}
