//
//  AppDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import Defaults
import FirebaseCore
import PostHog
import SwiftUI
import GoogleSignIn

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        if let darkAppearance = NSAppearance(named: .darkAqua) {
            NSApp.appearance = darkAppearance
        }
        GIDSignIn.sharedInstance.restorePreviousSignIn()
        
        // Configure dock icon visibility based on user preference
        configureDockIconVisibility()
        
        // This is helpful for debugging the new user experience, but should never be committed!
        //        if let appDomain = Bundle.main.bundleIdentifier {
        //            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        //            UserDefaults.standard.synchronize()
        //        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        AnalyticsManager.appQuit()
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Only launch the panel if it's not already visible
        if !PanelStateCoordinator.shared.state.panelOpened {
            PanelStateCoordinator.shared.launchPanel()
        }
        
        return true
    }
    
    private func configureDockIconVisibility() {
        let hideDockIcon = Defaults[.hideDockIcon]
        
        Task { @MainActor in
            if hideDockIcon {
                // Hide the dock icon - app becomes an accessory (background app)
                NSApp.setActivationPolicy(.accessory)
            } else {
                // Show the dock icon - app becomes a regular app
                NSApp.setActivationPolicy(.regular)
            }
        }
    }
}
