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
    @State var closedNoRemoteModels = false

    @State private var fetchingRemote = false
    @State private var fetchingLocal = false
    
    @AppStorage("closedRemote") var closedRemote = false
    @AppStorage("closedLocal") var closedLocal = false

    @AppStorage("closedOpenAI") var closedOpenAI = false
    @AppStorage("closedAnthropic") var closedAnthropic = false
    @AppStorage("closedXAI") var closedXAI = false
    @AppStorage("closedGoogleAI") var closedGoogleAI = false

    @AppStorage("closedNewRemoteData") private var closedNewRemoteData: Data = Data()
    var closedNewRemote: [String: Bool] {
        get {
             if let decoded = try? JSONDecoder().decode([String: Bool].self, from: closedNewRemoteData) {
                 return decoded
             }
            return [:]
        }
    }
        
    @AppStorage("closedDeprecatedRemoteData") private var closedDeprecatedRemoteData: Data = Data()
    var closedDeprecatedRemote: [String: Bool] {
        get {
             if let decoded = try? JSONDecoder().decode([String: Bool].self, from: closedDeprecatedRemoteData) {
                 return decoded
             }
            return [:]
        }
    }

    var body: some View {
        content
    }

    @ViewBuilder
    var content: some View {
        Group {
            if model.preferences.availableRemoteModels.isEmpty && model.preferences.remoteFetchFailed && !closedNoRemoteModels {
                noRemote
            }
            if model.remoteNeedsSetup && !closedRemote {
                remote
            }
            if model.preferences.availableRemoteModels.contains(where: { $0.isDeprecated && !(closedDeprecatedRemote[$0.id] ?? false) }) {
                let deprecatedModels = model.preferences.availableRemoteModels.filter { $0.isDeprecated && !(closedDeprecatedRemote[$0.id] ?? false) }
                deprecatedRemote(models: deprecatedModels)
            }
            if model.preferences.availableRemoteModels.contains(where: { $0.isNew && !(closedNewRemote[$0.id] ?? false) }) {
                let newModels = model.preferences.availableRemoteModels.filter { $0.isNew && !(closedNewRemote[$0.id] ?? false) }
                newRemote(models: newModels)
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
            if false && !closedGoogleAI {
                expired(.googleAI)
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
    
    var noRemote: some View {
        SetUpDialog(title: "Couldn't Get Remote Models", buttonText: fetchingRemote ? "Loading..." : "Retry") {
            Text("Onit couldn't load remote models - check your internet connection and try again!")
        } action: {
            Task {
                fetchingRemote = true
                await model.fetchRemoteModels()
                fetchingRemote = false
            }
        } closeAction: {
            closedNoRemoteModels = true
        }
    }

    func newRemote(models: [AIModel]) -> some View {
        SetUpDialog(title: "NEW Models Available!", buttonText: "Enable in Settings") {
            let newModelsByProvider = Dictionary(grouping: models.filter { $0.isNew }) { $0.provider }
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
            let deprecatedModelsByProvider = Dictionary(grouping: models.filter { $0.isDeprecated }) { $0.provider }
            let deprecatedModelsText = deprecatedModelsByProvider.map { provider, models in
                "\(provider.title)'s: " + models.map { $0.displayName }.joined(separator: ", ")
            }.joined(separator: " and ")
            Text("The following models are deprecated \(deprecatedModelsText). You can disable them in settings.")
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
        model.shrinkContent()
    }

    enum ClosureType {
        case new
        case deprecated
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

    var restartLocal: some View {
        SetUpDialog(title: "No Local Models Found", buttonText: fetchingLocal ? "Loading..." : "Try again") {
            Text("Onit couldn’t connect to local models - you may need to restart Ollama.")
        } action: {
            Task {
                fetchingLocal = true
                await model.fetchLocalModels()
                fetchingLocal = false
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
            case .googleAI:
                closedGoogleAI = true
            }
        }
    }
}
