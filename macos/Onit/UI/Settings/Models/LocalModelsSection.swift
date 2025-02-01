//
//  LocalModelsSection.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct LocalModelsSection: View {
    @Environment(\.model) var model

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
    
    // Validation states
    @State private var keepAliveValid: Bool = true
    @State private var numCtxValid: Bool = true
    @State private var temperatureValid: Bool = true
    @State private var topPValid: Bool = true
    @State private var topKValid: Bool = true

    var body: some View {
        ModelsSection(title: "Local Models") {
            VStack(alignment: .leading, spacing: 10) {
                title
                if let message = message {
                    Text(message)
                        .font(.system(size: 12))
                        .padding(.top, 5)
                }
                content
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            isOn = model.useLocal
            localEndpointString = model.preferences.localEndpointURL.absoluteString
            if let value = model.preferences.localKeepAlive { keepAlive = value }
            if let value = model.preferences.localNumCtx { numCtx = String(value) }
            if let value = model.preferences.localTemperature { temperature = String(value) }
            if let value = model.preferences.localTopP { topP = String(value) }
            if let value = model.preferences.localTopK { topK = String(value) }
        }
        .onChange(of: isOn) {
            model.useLocal = isOn
        }
    }

    var title: some View {
        VStack(alignment: .leading, spacing: 8) {
            // The implementation to turn off local models doesn't exist, so we never show the toggle.
            ModelTitle(title: "Ollama", isOn: $isOn, showToggle: .constant(false))
            
            HStack {
                Text("Endpoint URL:")
                    .foregroundStyle(.primary.opacity(0.65))
                    .font(.system(size: 12))
                    .fontWeight(.regular)
                TextField("", text: $localEndpointString)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 12))
                    .frame(maxWidth: 250)
                Spacer()
                Button {
                    Task {
                        fetching = true
                        if let localEndpointURL = URL(string: localEndpointString) {
                            model.updatePreferences { prefs in
                                prefs.localEndpointURL = localEndpointURL
                            }
                            
                            await model.fetchLocalModels()
                            
                            if model.localFetchFailed {
                                message = "Couldn't find any models at the provided URL."
                            } else {
                                message = "Models loaded successfully!"
                            }
                        } else {
                            message = "Local endpoint must be a valid URL"
                        }
                        fetching = false
                    }
                } label: {
                    Text("Set")
                }
                .disabled(fetching)
                .foregroundStyle(.white)
                .buttonStyle(.borderedProminent)
                .frame(height: 22)
                .fontWeight(.regular)
            }
            
            DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
                VStack(alignment: .leading, spacing: 8) {
                    Group {
                        HStack {
                            Text("Keep alive:")
                            TextField("e.g. 10m, 24h, -1, 3600", text: $keepAlive)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 150)
                                .onChange(of: keepAlive) {
                                    keepAliveValid = LocalModelValidation.validateKeepAlive(keepAlive)
                                    if keepAliveValid {
                                        model.updatePreferences { prefs in
                                            prefs.localKeepAlive = keepAlive.isEmpty ? nil : keepAlive
                                        }
                                    }
                                }
                                .foregroundStyle(keepAliveValid ? .primary : .red)
                            SettingInfoButton(
                                title: "Keep Alive",
                                description: "Controls how long the model will stay loaded into memory following the request",
                                defaultValue: "5m",
                                valueType: "Duration string (e.g. '10m', '24h') or integer seconds"
                            )
                        }
                        
                        HStack {
                            Text("Context window:")
                            TextField("", text: $numCtx)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: numCtx) {
                                    numCtxValid = LocalModelValidation.validateInt(numCtx, min: 1)
                                    if numCtxValid {
                                        if let value = Int(numCtx) {
                                            model.updatePreferences { prefs in
                                                prefs.localNumCtx = value
                                            }
                                        } else if numCtx.isEmpty {
                                            model.updatePreferences { prefs in
                                                prefs.localNumCtx = nil
                                            }
                                        }
                                    }
                                }
                                .foregroundStyle(numCtxValid ? .primary : .red)
                            SettingInfoButton(
                                title: "Context Window",
                                description: "Sets the size of the context window used to generate the next token",
                                defaultValue: "2048",
                                valueType: "Integer"
                            )
                        }
                        
                        HStack {
                            Text("Temperature:")
                            TextField("", text: $temperature)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: temperature) {
                                    temperatureValid = LocalModelValidation.validateFloat(temperature, min: 0.0, max: 2.0)
                                    if temperatureValid {
                                        if let value = Double(temperature) {
                                            model.updatePreferences { prefs in
                                                prefs.localTemperature = value
                                            }
                                        } else if temperature.isEmpty {
                                            model.updatePreferences { prefs in
                                                prefs.localTemperature = nil
                                            }
                                        }
                                    }
                                }
                                .foregroundStyle(temperatureValid ? .primary : .red)
                            SettingInfoButton(
                                title: "Temperature",
                                description: "The temperature of the model. Increasing the temperature will make the model answer more creatively",
                                defaultValue: "0.8",
                                valueType: "Float (0.0 - 2.0)"
                            )
                        }
                        
                        HStack {
                            Text("Top K:")
                            TextField("", text: $topK)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: topK) {
                                    topKValid = LocalModelValidation.validateInt(topK, min: 1)
                                    if topKValid {
                                        if let value = Int(topK) {
                                            model.updatePreferences { prefs in
                                                prefs.localTopK = value
                                            }
                                        } else if topK.isEmpty {
                                            model.updatePreferences { prefs in
                                                prefs.localTopK = nil
                                            }
                                        }
                                    }
                                }
                                .foregroundStyle(topKValid ? .primary : .red)
                            SettingInfoButton(
                                title: "Top K",
                                description: "Reduces the probability of generating nonsense. A higher value (e.g. 100) will give more diverse answers, while a lower value (e.g. 10) will be more conservative",
                                defaultValue: "40",
                                valueType: "Integer"
                            )
                        }
                        
                        HStack {
                            Text("Top P:")
                            TextField("", text: $topP)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: topP) {
                                    topPValid = LocalModelValidation.validateFloat(topP, min: 0.0, max: 1.0)
                                    if topPValid {
                                        if let value = Double(topP) {
                                            model.updatePreferences { prefs in
                                                prefs.localTopP = value
                                            }
                                        } else if topP.isEmpty {
                                            model.updatePreferences { prefs in
                                                prefs.localTopP = nil
                                            }
                                        }
                                    }
                                }
                                .foregroundStyle(topPValid ? .primary : .red)
                            SettingInfoButton(
                                title: "Top P",
                                description: "Works together with top-k. A higher value (e.g., 0.95) will lead to more diverse text, while a lower value (e.g., 0.5) will generate more focused and conservative text",
                                defaultValue: "0.9",
                                valueType: "Float (0.0 - 1.0)"
                            )
                        }
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
        if model.preferences.availableLocalModels.isEmpty {
            HStack(spacing: 0) {
                text
                Spacer(minLength: 8)
                button
            }
        } else {
            modelsView
        }
    }

    var link: String {
        "[Download Ollama](https://ollama.com/download/mac)"
    }

    var text: some View {
        (
            Text(.init(link))
            +
            Text("""
     to use Onit with local models. Models running locally on Ollama will be available here
    """
            )
        )
        .foregroundStyle(.primary.opacity(0.65))
        .font(.system(size: 12))
        .fontWeight(.regular)
    }

    @ViewBuilder
    var modelsView: some View {
        if isOn {
            GroupBox {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(model.preferences.availableLocalModels, id: \.self) { model in
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

    var button: some View {
        Button(action: {
            fetching = true
            Task {
                await model.fetchLocalModels()
                fetching = false
            }
        }) {
            if fetching {
                ProgressView()
                    .controlSize(.small)
            } else {
                Text("Reload")
            }
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    LocalModelsSection()
}
