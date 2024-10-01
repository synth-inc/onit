//
//  OnitApp.swift
//  Onit
//
//  Created by Benjamin Sage on 9/26/24.
//

import SwiftUI

@main
struct OnitApp: App {
//    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarScene()

        WindowGroup {
            TempView()
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 400, height: 84)

    }
}

struct TempView: View {
    @State var showWindow = false

    var body: some View {
        Button("Click here") {
            showWindow = true
        }
        .floatingPanel(isPresented: $showWindow) {
            Text("hello world")
        }
    }
}
