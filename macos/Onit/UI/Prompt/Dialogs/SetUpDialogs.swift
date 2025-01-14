//
//  SetUpDialogs.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct SetUpDialogs: View {
    @Environment(\.model) var model
    @Environment(\.openSettings) var openSettings

    var seenLocal: Bool

    @State var closedNoLocalModels = false

    @AppStorage("closedRemote") var closedRemote = false
    @AppStorage("closedLocal") var closedLocal = false

    var body: some View {
        content
    }

    @ViewBuilder
    var content: some View {
        if model.remoteNeedsSetup && !closedRemote {
            remote
        }
        if !closedLocal && model.availableLocalModels.isEmpty && !seenLocal {
            local
        }
        if !closedNoLocalModels && model.availableLocalModels.isEmpty && seenLocal {
            restartLocal
        }
    }

    var remote: some View {
        SetUpDialog(title: "Set Up Remote Models") {
            Text("Add API keys to connect to remote models for top performance.")
        } action: {
            settings()
        } closeAction: {
            closedRemote = true
        }
    }

    var local: some View {
        SetUpDialog(title: "Set Up Local Models") {
            Text("Get ")
            +
            Text("[Ollama](https://ollama.com/download/mac)")
            +
            Text(" to connect to local models that run directly on your computer for added privacy.")
        } action: {
            settings()
        } closeAction: {
            closedLocal = true
        }
        .tint(Color.blue400)
        .fixedSize(horizontal: false, vertical: true)
    }

    @State private var fetching = false
    var restartLocal: some View {
        SetUpDialog(title: "No Local Models Found", buttonText: fetching ? "Loading..." : "Try again") {
            Text("Onit couldn’t connect to local models - you may need to restart Ollama.")
        } action: {
            Task {
                fetching = true
                await model.fetchLocalModels()
                fetching = false
            }
        } closeAction: {
            closedNoLocalModels = true
        }
    }

    func settings() {
        NSApp.activate()
        if NSApp.isActive {
            openSettings()
        }
    }
}

