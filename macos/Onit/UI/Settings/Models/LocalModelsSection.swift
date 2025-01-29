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
