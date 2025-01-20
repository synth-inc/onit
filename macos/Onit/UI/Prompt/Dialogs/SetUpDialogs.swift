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

    @AppStorage("closedOpenAI") var closedOpenAI = false
    @AppStorage("closedAnthropic") var closedAnthropic = false
    @AppStorage("closedXAI") var closedXAI = false

    var body: some View {
        content
    }

    @ViewBuilder
    var content: some View {
        Group {
            if model.remoteNeedsSetup && !closedRemote {
                remote
            }
            if !closedLocal && model.preferences.availableLocalModels.isEmpty && !seenLocal {
                local
            }
            if !closedNoLocalModels && model.preferences.availableLocalModels.isEmpty && seenLocal {
                restartLocal
            }
            if false && !closedOpenAI {
                expired(.openAI)
            }
            if false && !closedAnthropic {
                expired(.anthropic)
            }
            if false && !closedXAI {
                expired(.xAI)
            }
        }
        .background {
            GeometryReader { g in
                Color.clear
                    .onAppear {
                        model.setUpHeight = g.size.height
                    }
                    .onChange(of: g.size.height) {
                        model.setUpHeight = g.size.height
                    }
                    .onDisappear {
                        model.setUpHeight = 0
                    }
            }
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

    func expired(_ provider: AIModel.ModelProvider) -> some View {
        SetUpDialog(title: "Couldn’t connect to \(provider.title)", buttonText: "Go to Settings") {
            Text("Onit couldn’t connect to remote API providers - your tokens may have expired.")
        } action: {
            settings()
        } closeAction: {
            switch provider {
            case .openAI:
                closedOpenAI = true
            case .anthropic:
                closedAnthropic = true
            case .xAI:
                closedXAI = true
            }
        }
    }
}

