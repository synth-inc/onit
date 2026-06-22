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
    @State private var message: String? = nil
    @State private var localEndpointString: String = ""
    @State private var showAdvanced: Bool = false
    @State private var keepAlive: String = ""
    @State private var numCtx: String = ""
    @State private var temperature: String = ""
    @State private var topP: String = ""
    @State private var topK: String = ""
    @State private var timeout: String = ""

    // Validation states and errors
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
        ModelsSection(title: String.localized("Local Models", table: "Models")) {
            VStack(alignment: .leading, spacing: 10) {
                title
                if let message = message {
                    Text(message)
                        .font(.system(size: 12))
                        .padding(.top, 5)
                }
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

            HStack(alignment: .center) {
                Text(String.localized("Endpoint URL:", table: "Models"))
                    .foregroundStyle(Color.S_0.opacity(0.65))
                    .font(.system(size: 12))
                    .fontWeight(.regular)
                TextField("", text: $localEndpointString)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 13, weight: .regular))
                    .frame(maxWidth: 250)
                    .padding(0)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 7)
                    .background(Color.T_8)
                    .addBorder(cornerRadius: 5, stroke: Color.genericBorder)
                Spacer()
                SimpleButton(
                    isLoading: fetching,
                    disabled: fetching,
                    text: String.localized("Set", table: "Models"),
                    textColor: Color.white,
                    action: {
                        Task {
                            fetching = true
                            if let localEndpointURL = URL(string: localEndpointString) {
                                self.localEndpointURL = localEndpointURL

                                await appState.fetchLocalModels()

                                if appState.localFetchFailed {
                                    message = String.localized("Couldn't find any models at the provided URL.", table: "Models")
                                } else {
                                    message = String.localized("Models loaded successfully!", table: "Models")
                                }
                            } else {
                                message = String.localized("Local endpoint must be a valid URL", table: "Models")
                            }
                            fetching = false
                        }
                    },
                    background: Color.blue
                )
            }
            
            content
            
            DisclosureGroup(String.localized("Advanced", table: "Models"), isExpanded: $showAdvanced) {
                VStack(alignment: .leading, spacing: 8) {
                    StreamingToggle(isOn: $streamResponse.local)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(String.localized("Keep alive:", table: "Models"))
                            TextField(String.localized("e.g. 10m, 24h, -1, 3600", table: "Models"), text: $keepAlive)
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
                                            String.localized("Invalid format. Use duration (e.g. 10m, 24h) or seconds", table: "Models")
                                    }
                                }
                            SettingInfoButton(
                                title: String.localized("Keep Alive", table: "Models"),
                                description:
                                    String.localized("Controls how long the model will stay loaded into memory following the request", table: "Models"),
                                defaultValue: defaultKeepAlive,
                                valueType: String.localized("Duration string (e.g. '10m', '24h') or integer seconds", table: "Models")
                            )
                        }
                        SettingErrorMessage(message: keepAliveError)

                        HStack {
                            Text(String.localized("Request timeout (seconds):", table: "Models"))
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
                                        timeoutError = String.localized("Must be a positive integer", table: "Models")
                                    }
                                }
                            SettingInfoButton(
                                title: String.localized("Request Timeout", table: "Models"),
                                description:
                                    String.localized("Controls how long to wait for a response from the model before timing out (in seconds)", table: "Models"),
                                defaultValue: String(defaultTimeout),
                                valueType: String.localized("Integer (seconds)", table: "Models")
                            )
                        }
                        SettingErrorMessage(message: timeoutError)

                        HStack {
                            Text(String.localized("Context window:", table: "Models"))
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
                                        numCtxError = String.localized("Must be a positive integer", table: "Models")
                                    }
                                }
                            SettingInfoButton(
                                title: String.localized("Context Window", table: "Models"),
                                description:
                                    String.localized("Sets the size of the context window used to generate the next token", table: "Models"),
                                defaultValue: String(defaultNumCtx),
                                valueType: String.localized("Integer", table: "Models")
                            )
                        }
                        SettingErrorMessage(message: numCtxError)

                        HStack {
                            Text(String.localized("Temperature:", table: "Models"))
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
                                        temperatureError = String.localized("Must be a number between 0.0 and 2.0", table: "Models")
                                    }
                                }
                            SettingInfoButton(
                                title: String.localized("Temperature", table: "Models"),
                                description:
                                    String.localized("The temperature of the model. Increasing the temperature will make the model answer more creatively", table: "Models"),
                                defaultValue: String(defaultTemperature),
                                valueType: String.localized("Float (0.0 - 2.0)", table: "Models")
                            )
                        }
                        SettingErrorMessage(message: temperatureError)

                        HStack {
                            Text(String.localized("Top K:", table: "Models"))
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
                                        topKError = String.localized("Must be a positive integer", table: "Models")
                                    }
                                }
                            SettingInfoButton(
                                title: String.localized("Top K", table: "Models"),
                                description:
                                    String.localized("Reduces the probability of generating nonsense. A higher value (e.g. 100) will give more diverse answers, while a lower value (e.g. 10) will be more conservative", table: "Models"),
                                defaultValue: String(defaultTopK),
                                valueType: String.localized("Integer", table: "Models")
                            )
                        }
                        SettingErrorMessage(message: topKError)

                        HStack {
                            Text(String.localized("Top P:", table: "Models"))
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
                                        topPError = String.localized("Must be a number between 0.0 and 1.0", table: "Models")
                                    }
                                }
                            SettingInfoButton(
                                title: String.localized("Top P", table: "Models"),
                                description:
                                    String.localized("Works together with top-k. A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text", table: "Models"),
                                defaultValue: String(defaultTopP),
                                valueType: String.localized("Float (0.0 - 1.0)", table: "Models")
                            )
                        }
                        SettingErrorMessage(message: topPError)

                        DividerHorizontal()
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
                            Text(String.localized("Restore Defaults", table: "Models"))
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
            HStack(alignment: .top, spacing: 0) {
                text
                Spacer(minLength: 8)
                button
            }
        } else {
            modelsView
        }
    }

    var link: String {
        "[\(String.localized("Download Ollama", table: "Models"))](https://ollama.com/download/mac)"
    }

    var text: some View {
        (Text(.init(link))
            + Text(
                String.localized(" to use Onit with local models. Models running locally on Ollama will be available here.", table: "Models")
            ))
            .foregroundStyle(Color.S_0.opacity(0.65))
            .font(.system(size: 12))
            .fontWeight(.regular)
    }

    @ViewBuilder
    var modelsView: some View {
        if isOn {
            GroupBox {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(availableLocalModels, id: \.self) { model in
                        LocalModelToggle(modelName: model)
                            .frame(height: 36)
                    }
                }
                .padding(.vertical, -4)
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    var button: some View {
        SimpleButton(
            isLoading: fetching,
            disabled: fetching,
            text: String.localized("Reload", table: "Models"),
            textColor: Color.white,
            action: {
                fetching = true
                Task {
                    await appState.fetchLocalModels()
                    fetching = false
                }
            },
            background: Color.blue
        )
    }
}

#Preview {
    LocalModelsSection()
}
