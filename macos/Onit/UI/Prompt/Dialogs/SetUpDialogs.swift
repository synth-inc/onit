//
//  SetUpDialogs.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import Defaults
import SwiftUI

struct SetUpDialogs: View {
    @Environment(\.appState) var appState
    @Environment(\.remoteModels) var remoteModels
    @Environment(\.openSettings) var openSettings
    @Environment(\.windowState) private var state

    @State private var fetchingRemote = false
    @State private var fetchingLocal = false
    @State private var debounceTask: DispatchWorkItem?

    @Default(.closedRemote) var closedRemote
    @Default(.closedLocal) var closedLocal
    @Default(.closedOpenAI) var closedOpenAI
    @Default(.closedAnthropic) var closedAnthropic
    @Default(.closedXAI) var closedXAI
    @Default(.closedGoogleAI) var closedGoogleAI
    @Default(.closedDeepSeek) var closedDeepSeek
    @Default(.closedPerplexity) var closedPerplexity
    @Default(.closedNoLocalModels) var closedNoLocalModels
    @Default(.closedNoRemoteModels) var closedNoRemoteModels
    @Default(.seenLocal) var seenLocal
    @Default(.closedNewRemoteData) var closedNewRemoteData
    @Default(.closedDeprecatedRemoteData) var closedDeprecatedRemoteData
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.availableLocalModels) var availableLocalModels

    var closedNewRemote: [String: Bool] {
        if let decoded = try? JSONDecoder().decode([String: Bool].self, from: closedNewRemoteData) {
            return decoded
        }
        return [:]
    }

    var closedDeprecatedRemote: [String: Bool] {
        if let decoded = try? JSONDecoder().decode(
            [String: Bool].self, from: closedDeprecatedRemoteData)
        {
            return decoded
        }
        return [:]
    }
    
    let scrollMaxHeight: CGFloat = 230

    init() {
        // resetAppStorageFlags()
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack {
                content
            }
            .onHeightChanged(callback: updateHeight)
            .onChange(of: availableLocalModels.count) { _, new in
                if new != 0 {
                    seenLocal = true
                }
            }
            .padding(.bottom, 4) 
        }
        .frame(maxHeight: min(state.setUpHeight, scrollMaxHeight))
        .overlay(
            Group {
                if state.setUpHeight >= scrollMaxHeight {
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.black, location: 0),
                            .init(color: Color.black.opacity(0), location: 1)
                        ]),
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 50)
                }
            },
            alignment: .bottom
        )
    }
    
    private func updateHeight(newHeight: CGFloat) {
        debounceTask?.cancel()
        
        let task = DispatchWorkItem {
            guard state.panel?.isVisible == true else {
                state.setUpHeight = 0
                return
            }
            
            state.setUpHeight = newHeight
        }
        debounceTask = task
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: task)
    }

    @ViewBuilder
    var content: some View {
        VStack(spacing: 0) {
//            #if DEBUG
//                noRemote
//                remote
//                local
//                restartLocal
//                expired(.openAI)
//                expired(.anthropic)
//            #endif
//            
            if availableRemoteModels.isEmpty && appState.remoteFetchFailed && !closedNoRemoteModels {
                noRemote
            }
            if remoteModels.remoteNeedsSetup && !closedRemote {
                remote
            }
            if availableRemoteModels.contains(where: {
                $0.isDeprecated && !(closedDeprecatedRemote[$0.id] ?? false)
            }) {
                let deprecatedModels = availableRemoteModels.filter {
                    $0.isDeprecated && !(closedDeprecatedRemote[$0.id] ?? false)
                }
                deprecatedRemote(models: deprecatedModels)
            }
            if availableRemoteModels.contains(where: {
                $0.isNew && !(closedNewRemote[$0.id] ?? false)
            }) {
                let newModels = availableRemoteModels.filter {
                    $0.isNew && !(closedNewRemote[$0.id] ?? false)
                }
                newRemote(models: newModels)
            }
            if !closedLocal && availableLocalModels.isEmpty && !seenLocal {
                local
            }
            if !closedNoLocalModels && availableLocalModels.isEmpty && seenLocal {
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
            if false && !closedGoogleAI {
                expired(.googleAI)
            }
            if false && !closedDeepSeek {
                expired(.deepSeek)
            }
            if false && !closedPerplexity {
                expired(.perplexity)
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

    var noRemote: some View {
        SetUpDialog(
            title: "Couldn't Get Remote Models", buttonText: fetchingRemote ? "Loading..." : "Retry"
        ) {
            Text("Onit couldn't load remote models - check your internet connection and try again!")
        } action: {
            Task {
                fetchingRemote = true
                await appState.fetchRemoteModels()
                fetchingRemote = false
            }
        } closeAction: {
            closedNoRemoteModels = true
        }
    }

    func newRemote(models: [AIModel]) -> some View {
        SetUpDialog(title: "NEW Models Available!", buttonText: "Enable in Settings") {
            let newModelsByProvider = Dictionary(grouping: models.filter { $0.isNew }) {
                $0.provider
            }
            let newModelsText = newModelsByProvider.map { provider, models in
                "\(provider.title): " + models.map { $0.displayName }.joined(separator: ", ")
            }.joined(separator: " and ")
            Text("New models from \(newModelsText). View and enable them in settings.")
        } action: {
            settings()
            handleModelClosure(models: models, closureType: .new)
        } closeAction: {
            handleModelClosure(models: models, closureType: .new)
        }
    }

    func deprecatedRemote(models: [AIModel]) -> some View {
        SetUpDialog(title: "Deprecated Models", buttonText: "Disable in Settings") {
            let deprecatedModelsByProvider = Dictionary(grouping: models.filter { $0.isDeprecated })
            {
                $0.provider
            }
            let deprecatedModelsText = deprecatedModelsByProvider.map { provider, models in
                "\(provider.title)'s: " + models.map { $0.displayName }.joined(separator: ", ")
            }.joined(separator: " and ")
            Text(
                "The following models are deprecated \(deprecatedModelsText). You can disable them in settings."
            )
        } action: {
            settings()
            handleModelClosure(models: models, closureType: .deprecated)
        } closeAction: {
            handleModelClosure(models: models, closureType: .deprecated)
        }
    }

    func handleModelClosure(models: [AIModel], closureType: ClosureType) {
        var updatedClosureData: [String: Bool]
        switch closureType {
        case .new:
            updatedClosureData = closedNewRemote
        case .deprecated:
            updatedClosureData = closedDeprecatedRemote
        }
        for model in models {
            updatedClosureData[model.id] = true
        }
        if let encoded = try? JSONEncoder().encode(updatedClosureData) {
            switch closureType {
            case .new:
                closedNewRemoteData = encoded
            case .deprecated:
                closedDeprecatedRemoteData = encoded
            }
        }
    }

    enum ClosureType {
        case new
        case deprecated
    }

    var local: some View {
        SetUpDialog(title: "Set Up Local Models") {
            Text("Get ")
                + Text("[Ollama](https://ollama.com/download/mac)")
                + Text(
                    " to connect to local models that run directly on your computer for added privacy."
                )
        } action: {
            settings()
        } closeAction: {
            closedLocal = true
        }
        .tint(Color.blue400)
        .fixedSize(horizontal: false, vertical: true)
    }

    var restartLocal: some View {
        SetUpDialog(
            title: "No Local Models Found", buttonText: fetchingLocal ? "Loading..." : "Try again"
        ) {
            Text("Onit couldn't connect to local models - you may need to restart Ollama.")
        } action: {
            Task {
                fetchingLocal = true
                await appState.fetchLocalModels()
                fetchingLocal = false
            }
        } closeAction: {
            closedNoLocalModels = true
        }
    }

    func settings() {
        NSApp.activate()
        if NSApp.isActive {
            appState.setSettingsTab(tab: .models)
            openSettings()
        }
    }

    func expired(_ provider: AIModel.ModelProvider) -> some View {
        SetUpDialog(title: "Couldn't connect to \(provider.title)", buttonText: "Go to Settings") {
            Text("Onit couldn't connect to remote API providers - your tokens may have expired.")
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
            case .googleAI:
                closedGoogleAI = true
            case .deepSeek:
                closedDeepSeek = true
            case .perplexity:
                closedPerplexity = true
            case .custom:
                break  // TODO: KNA -
            }
        }
    }

    func resetAppStorageFlags() {
        closedRemote = false
        closedLocal = false
        closedOpenAI = false
        closedAnthropic = false
        closedXAI = false
        closedGoogleAI = false
        closedDeepSeek = false
    }
}
