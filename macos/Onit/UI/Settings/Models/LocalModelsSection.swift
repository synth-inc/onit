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
    @State private var keepAlive: Bool = false
    @State private var numCtx: String = ""
    @State private var temperature: String = ""
    @State private var topP: String = ""
    @State private var minP: String = ""

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
            keepAlive = model.preferences.localKeepAlive
            if let value = model.preferences.localNumCtx { numCtx = String(value) }
            if let value = model.preferences.localTemperature { temperature = String(value) }
            if let value = model.preferences.localTopP { topP = String(value) }
            if let value = model.preferences.localMinP { minP = String(value) }
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
                    Toggle("Keep model alive", isOn: $keepAlive)
                        .onChange(of: keepAlive) {
                            model.updatePreferences { prefs in
                                prefs.localKeepAlive = keepAlive
                            }
                        }
                    
                    Group {
                        HStack {
                            Text("Context window:")
                            TextField("", text: $numCtx)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: numCtx) {
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
                        
                        HStack {
                            Text("Temperature:")
                            TextField("", text: $temperature)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: temperature) {
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
                        
                        HStack {
                            Text("Top P:")
                            TextField("", text: $topP)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: topP) {
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
                        
                        HStack {
                            Text("Min P:")
                            TextField("", text: $minP)
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 100)
                                .onChange(of: minP) {
                                    if let value = Double(minP) {
                                        model.updatePreferences { prefs in
                                            prefs.localMinP = value
                                        }
                                    } else if minP.isEmpty {
                                        model.updatePreferences { prefs in
                                            prefs.localMinP = nil
                                        }
                                    }
                                }
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
