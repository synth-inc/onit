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
        // Configure crash reporting first
        NSSetUncaughtExceptionHandler { exception in
            print("Uncaught exception: \(exception)")
        }
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // This is helpful for debugging the new user experience, but should never be committed!
        //        if let appDomain = Bundle.main.bundleIdentifier {
        //            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        //            UserDefaults.standard.synchronize()
        //        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Capture app quit event
        PostHogSDK.shared.capture("app_quit")
    }
}
