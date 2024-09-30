//
//  OnitApp.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI

@main
struct OnitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .foregroundStyle(.white)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 84)
    }
}
