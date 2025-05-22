//
//  AppDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import FirebaseCore
import PostHog
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        if let darkAppearance = NSAppearance(named: .darkAqua) {
            NSApp.appearance = darkAppearance
        }
        // This is helpful for debugging the new user experience, but should never be committed!
        //        if let appDomain = Bundle.main.bundleIdentifier {
        //            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        //            UserDefaults.standard.synchronize()
        //        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        PostHogSDK.shared.capture("app_quit")
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Only launch the panel if it's not already visible
        if !PanelStateCoordinator.shared.state.panelOpened {
            PanelStateCoordinator.shared.launchPanel()
        }
        
        return true
    }
}
