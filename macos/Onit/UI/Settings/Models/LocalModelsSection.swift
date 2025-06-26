//
//  LocalModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import Defaults
import SwiftUI

struct LocalModelsSection: View {
    @Environment(\.appState) var appState

    @State private var isOn: Bool = false
    @State private var fetching: Bool = false
    @State private var fetchSuccessMessage: String? = nil
    @State private var localEndpointString: String = ""
    @State private var showAdvanced: Bool = false
    @State private var keepAlive: String = ""
    @State private var numCtx: String = ""
    @State private var temperature: String = ""
    @State private var topP: String = ""
    @State private var topK: String = ""
    @State private var timeout: String = ""

    // Validation states and errors
    @State private var fetchError: String? = nil
    @State private var keepAliveError: String? = nil
    @State private var numCtxError: String? = nil
    @State private var temperatureError: String? = nil
    @State private var topPError: String? = nil
    @State private var topKError: String? = nil
    @State private var timeoutError: String? = nil

    @Default(.availableLocalModels) var availableLocalModels
    @Default(.useLocal) var useLocal
    @Default(.streamResponse) var streamResponse
    @Default(.localEndpointURL) var localEndpointURL
    @Default(.localKeepAlive) var localKeepAlive
    @Default(.localNumCtx) var localNumCtx
    @Default(.localTemperature) var localTemperature
    @Default(.localTopP) var localTopP
    @Default(.localTopK) var localTopK
    @Default(.localRequestTimeout) var localRequestTimeout

    // Default values
    private let defaultKeepAlive = "5m"
    private let defaultNumCtx = 2048
    private let defaultTemperature = 0.8
    private let defaultTopP = 0.9
    private let defaultTopK = 40
    private let defaultTimeout = 60.0

    var body: some View {
        ModelsSection(title: "Local Models") {
            VStack(alignment: .leading, spacing: 10) {
                title
                
                if let fetchError = fetchError {
                    ModelErrorView(errorMessage: fetchError)
                } else if let fetchSuccessMessage = fetchSuccessMessage {
                    Text(fetchSuccessMessage)
                        .font(.system(size: 12))
                        .padding(.top, 5)
                }
                
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            isOn = useLocal
            localEndpointString = localEndpointURL.absoluteString
            if let value = localKeepAlive { keepAlive = value }
            if let value = localNumCtx { numCtx = String(value) }
            if let value = localTemperature { temperature = String(value) }
            if let value = localTopP { topP = String(value) }
            if let value = localTopK { topK = String(value) }
            if let value = localRequestTimeout { timeout = String(value) }
        }
        .onChange(of: isOn) {
            useLocal = isOn
        }
    }

    var title: some View {
        VStack(alignment: .leading, spacing: 8) {
            // The implementation to turn off local models doesn't exist, so we never show the toggle.
            ModelTitle(title: "Ollama", isOn: $isOn, showToggle: false)

            HStack(alignment: .center, spacing: 8) {
                Text("Endpoint URL:")
                    .foregroundStyle(.primary.opacity(0.65))
                    .font(.system(size: 12))
                    .fontWeight(.regular)
                
                TextField("", text: $localEndpointString)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .frame(maxWidth: 250)
                
                SimpleButton(
                    text: "Set",
                    loading: fetching,
                    disabled: fetching,
                    background: .blue
                ) {
                    Task {
                        fetching = true
                        if let localEndpointURL = URL(string: localEndpointString) {
                            self.localEndpointURL = localEndpointURL

                            await appState.fetchLocalModels()

                            if appState.localFetchFailed {
                                fetchSuccessMessage = nil
                                fetchError = "Couldn't find any models at the provided URL."
                            } else {
                                fetchSuccessMessage = "✅ Models loaded successfully!"
                                fetchError = nil
                            }
                        } else {
                            fetchSuccessMessage = nil
                            fetchError = "Local endpoint must be a valid URL"
                        }
                        
                        fetching = false
                    }
                }
            }
            
            DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                VStack(alignment: .leading, spacing: 8) {
                    StreamingToggle(isOn: $streamResponse.local)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Keep alive:")
                            TextField("e.g. 10m, 24h, -1, 3600", text: $keepAlive)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 150)
                                .onChange(of: keepAlive) {
                                    if keepAlive.isEmpty {
                                        keepAliveError = nil
                                        localKeepAlive = nil
                                    } else if LocalModelValidation.validateKeepAlive(keepAlive) {
                                        keepAliveError = nil
                                        localKeepAlive = keepAlive
                                    } else {
                                        keepAliveError =
                                            "Invalid format. Use duration (e.g. 10m, 24h) or seconds"
                                    }
                                }
                            SettingInfoButton(
                                title: "Keep Alive",
                                description:
                                    "Controls how long the model will stay loaded into memory following the request",
                                defaultValue: defaultKeepAlive,
                                valueType: "Duration string (e.g. '10m', '24h') or integer seconds"
                            )
                        }
                        if let errorMessage = keepAliveError {
                            ModelErrorView(errorMessage: errorMessage)
                        }

                        HStack {
                            Text("Request timeout (seconds):")
                            TextField("", text: $timeout)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: timeout) {
                                    if timeout.isEmpty {
                                        timeoutError = nil
                                        localRequestTimeout = nil
                                    } else if LocalModelValidation.validateInt(timeout, min: 1) {
                                        timeoutError = nil
                                        if let value = Double(timeout) {
                                            localRequestTimeout = value
                                        }
                                    } else {
                                        timeoutError = "Must be a positive integer"
                                    }
                                }
                            SettingInfoButton(
                                title: "Request Timeout",
                                description:
                                    "Controls how long to wait for a response from the model before timing out (in seconds)",
                                defaultValue: String(defaultTimeout),
                                valueType: "Integer (seconds)"
                            )
                        }
                        if let errorMessage = timeoutError {
                            ModelErrorView(errorMessage: errorMessage)
                        }

                        HStack {
                            Text("Context window:")
                            TextField("", text: $numCtx)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: numCtx) {
                                    if numCtx.isEmpty {
                                        numCtxError = nil
                                        localNumCtx = nil
                                    } else if LocalModelValidation.validateInt(numCtx, min: 1) {
                                        numCtxError = nil
                                        if let value = Int(numCtx) {
                                            localNumCtx = value
                                        }
                                    } else {
                                        numCtxError = "Must be a positive integer"
                                    }
                                }
                            SettingInfoButton(
                                title: "Context Window",
                                description:
                                    "Sets the size of the context window used to generate the next token",
                                defaultValue: String(defaultNumCtx),
                                valueType: "Integer"
                            )
                        }
                        if let errorMessage = numCtxError {
                            ModelErrorView(errorMessage: errorMessage)
                        }

                        HStack {
                            Text("Temperature:")
                            TextField("", text: $temperature)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: temperature) {
                                    if temperature.isEmpty {
                                        temperatureError = nil
                                        localTemperature = nil
                                    } else if LocalModelValidation.validateFloat(
                                        temperature, min: 0.0, max: 2.0)
                                    {
                                        temperatureError = nil
                                        if let value = Double(temperature) {
                                            localTemperature = value
                                        }
                                    } else {
                                        temperatureError = "Must be a number between 0.0 and 2.0"
                                    }
                                }
                            SettingInfoButton(
                                title: "Temperature",
                                description:
                                    "The temperature of the model. Increasing the temperature will make the model answer more creatively",
                                defaultValue: String(defaultTemperature),
                                valueType: "Float (0.0 - 2.0)"
                            )
                        }
                        if let errorMessage = temperatureError {
                            ModelErrorView(errorMessage: errorMessage)
                        }

                        HStack {
                            Text("Top K:")
                            TextField("", text: $topK)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: topK) {
                                    if topK.isEmpty {
                                        topKError = nil
                                        localTopK = nil
                                    } else if LocalModelValidation.validateInt(topK, min: 1) {
                                        topKError = nil
                                        if let value = Int(topK) {
                                            localTopK = value
                                        }
                                    } else {
                                        topKError = "Must be a positive integer"
                                    }
                                }
                            SettingInfoButton(
                                title: "Top K",
                                description:
                                    "Reduces the probability of generating nonsense. A higher value (e.g. 100) will give more diverse answers, while a lower value (e.g. 10) will be more conservative",
                                defaultValue: String(defaultTopK),
                                valueType: "Integer"
                            )
                        }
                        if let errorMessage = topKError {
                            ModelErrorView(errorMessage: errorMessage)
                        }

                        HStack {
                            Text("Top P:")
                            TextField("", text: $topP)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: topP) {
                                    if topP.isEmpty {
                                        topPError = nil
                                        localTopP = nil
                                    } else if LocalModelValidation.validateFloat(
                                        topP, min: 0.0, max: 1.0)
                                    {
                                        topPError = nil
                                        if let value = Double(topP) {
                                            localTopP = value
                                        }
                                    } else {
                                        topPError = "Must be a number between 0.0 and 1.0"
                                    }
                                }
                            SettingInfoButton(
                                title: "Top P",
                                description:
                                    "Works together with top-k. A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text",
                                defaultValue: String(defaultTopP),
                                valueType: "Float (0.0 - 1.0)"
                            )
                        }
                        if let errorMessage = topPError {
                            ModelErrorView(errorMessage: errorMessage)
                        }

                        Divider()
                            .padding(.vertical, 4)

                        Button {
                            // Restore defaults
                            keepAlive = defaultKeepAlive
                            timeout = String(defaultTimeout)
                            numCtx = String(defaultNumCtx)
                            temperature = String(defaultTemperature)
                            topK = String(defaultTopK)
                            topP = String(defaultTopP)

                            // Update preferences
                            localKeepAlive = defaultKeepAlive
                            localRequestTimeout = defaultTimeout
                            localNumCtx = defaultNumCtx
                            localTemperature = defaultTemperature
                            localTopK = defaultTopK
                            localTopP = defaultTopP

                            // Clear any errors
                            keepAliveError = nil
                            timeoutError = nil
                            numCtxError = nil
                            temperatureError = nil
                            topKError = nil
                            topPError = nil
                        } label: {
                            Text("Restore Defaults")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .font(.system(size: 12))
                }
                .padding(.leading, 8)
                .padding(.top, 4)
            }
            .font(.system(size: 12))
            .fontWeight(.regular)
        }
    }

    @ViewBuilder
    var content: some View {
        if availableLocalModels.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                text
                reloadButton
            }
        } else {
            modelsView
        }
    }

    var link: String {
        "[Download Ollama](https://ollama.com/download/mac)"
    }

    var text: some View {
        (Text(.init(link))
            + Text(
                """
                 to use Onit with local models. Models running locally on Ollama will be available here
                """
            ))
            .foregroundStyle(.primary.opacity(0.65))
            .font(.system(size: 12))
            .fontWeight(.regular)
    }

    @ViewBuilder
    var modelsView: some View {
        if isOn {
            GroupBox {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(availableLocalModels, id: \.self) { model in
                        Toggle(isOn: .constant(true)) {
                            Text(model)
                                .font(.system(size: 13))
                                .fontWeight(.regular)
                                .opacity(0.85)
                        }
                        .frame(height: 36)
                    }
                }
                .padding(.vertical, -4)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    var reloadButton: some View {
        SimpleButton(
            text: "Reload",
            loading: fetching,
            disabled: fetching,
            background: .blue
        ) {
            fetching = true
            
            Task {
                await appState.fetchLocalModels()
                fetching = false
            }
        }
    }
}

#Preview {
    LocalModelsSection()
}
