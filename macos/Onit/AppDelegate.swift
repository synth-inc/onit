//
//  AppDelegate.swift
//  Onit
//
//  Created by Kévin Naudin on 21/01/2025.
//

import FirebaseCore
import PostHog
import SwiftUI
import SwiftyBeaver

let log = SwiftyBeaver.self

class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        FirebaseApp.configure()
        configureSwiftBeaver()

        // This is helpful for debugging the new user experience, but should never be committed!
        //        if let appDomain = Bundle.main.bundleIdentifier {
        //            UserDefaults.standard.removePersistentDomain(forName: appDomain)
        //            UserDefaults.standard.synchronize()
        //        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        PostHogSDK.shared.capture("app_quit")
    }
    
    private func configureSwiftBeaver() {
        #if DEBUG
        let logsDirectory = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!
        let logFileURL = logsDirectory.appendingPathComponent("Logs/Onit.log")
        
        let file = FileDestination(logFileURL: logFileURL)
        let console = ConsoleDestination()
        
        log.addDestination(console)
        log.addDestination(file)
        #endif
    }
}
