//
//  LocalModelAdvancedOptionsView.swift
//  Onit
//
//  Created by Kévin Naudin on 14/02/2025.
//

import SwiftUI

struct LocalModelAdvancedOptionsView: View {
    @Binding var storedStreamResponse: Bool
    @Binding var storedKeepAlive: String?
    @Binding var storedRequestTimeout: TimeInterval?
    @Binding var storedOptions: LocalChatOptions
    
    var streamAdditionalInfo: String?
    
    @State private var keepAliveValue: String = ""
    @State private var numCtxValue: String = ""
    @State private var temperatureValue: String = ""
    @State private var topPValue: String = ""
    @State private var topKValue: String = ""
    @State private var timeoutValue: String = ""
    
    // Validation states and errors
    @State private var keepAliveError: String? = nil
    @State private var numCtxError: String? = nil
    @State private var temperatureError: String? = nil
    @State private var topPError: String? = nil
    @State private var topKError: String? = nil
    @State private var timeoutError: String? = nil
    
    // Default values
    private let defaultKeepAlive = "5m"
    private let defaultNumCtx = 2048
    private let defaultTemperature = 0.8
    private let defaultTopP = 0.9
    private let defaultTopK = 40
    private let defaultTimeout = 60.0
    
    @State private var showAdvanced: Bool = false
    
    var body: some View {
        DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: 8) {
                StreamingToggle(isOn: $storedStreamResponse, additionalInfo: streamAdditionalInfo)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Keep alive:")
                        TextField("", text: $keepAliveValue)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 150)
                            .onChange(of: keepAliveValue) {
                                if keepAliveValue.isEmpty {
                                    keepAliveError = nil
                                    storedKeepAlive = nil
                                } else if LocalModelValidation.validateKeepAlive(keepAliveValue) {
                                    keepAliveError = nil
                                    storedKeepAlive = keepAliveValue
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
                            valueType: "Duration string (e.g. '10m', '24h', '3600') or integer seconds"
                        )
                    }
                    SettingErrorMessage(message: keepAliveError)

                    HStack {
                        Text("Request timeout (seconds):")
                        TextField("", text: $timeoutValue)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 100)
                            .onChange(of: timeoutValue) {
                                if timeoutValue.isEmpty {
                                    timeoutError = nil
                                    storedRequestTimeout = nil
                                } else if LocalModelValidation.validateInt(timeoutValue, min: 1) {
                                    timeoutError = nil
                                    if let value = Double(timeoutValue) {
                                        storedRequestTimeout = value
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
                    SettingErrorMessage(message: timeoutError)

                    HStack {
                        Text("Context window:")
                        TextField("", text: $numCtxValue)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 100)
                            .onChange(of: numCtxValue) {
                                if numCtxValue.isEmpty {
                                    numCtxError = nil
                                    storedOptions.num_ctx = nil
                                } else if LocalModelValidation.validateInt(numCtxValue, min: 1) {
                                    numCtxError = nil
                                    if let value = Int(numCtxValue) {
                                        storedOptions.num_ctx = value
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
                    SettingErrorMessage(message: numCtxError)

                    HStack {
                        Text("Temperature:")
                        TextField("", text: $temperatureValue)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 100)
                            .onChange(of: temperatureValue) {
                                if temperatureValue.isEmpty {
                                    temperatureError = nil
                                    storedOptions.temperature = nil
                                } else if LocalModelValidation.validateFloat(
                                    temperatureValue, min: 0.0, max: 2.0)
                                {
                                    temperatureError = nil
                                    if let value = Double(temperatureValue) {
                                        storedOptions.temperature = value
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
                    SettingErrorMessage(message: temperatureError)

                    HStack {
                        Text("Top K:")
                        TextField("", text: $topKValue)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 100)
                            .onChange(of: topKValue) {
                                if topKValue.isEmpty {
                                    topKError = nil
                                    storedOptions.top_k = nil
                                } else if LocalModelValidation.validateInt(topKValue, min: 1) {
                                    topKError = nil
                                    if let value = Int(topKValue) {
                                        storedOptions.top_k = value
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
                    SettingErrorMessage(message: topKError)

                    HStack {
                        Text("Top P:")
                        TextField("", text: $topPValue)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 100)
                            .onChange(of: topPValue) {
                                if topPValue.isEmpty {
                                    topPError = nil
                                    storedOptions.top_p = nil
                                } else if LocalModelValidation.validateFloat(
                                    topPValue, min: 0.0, max: 1.0)
                                {
                                    topPError = nil
                                    if let value = Double(topPValue) {
                                        storedOptions.top_p = value
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
                    SettingErrorMessage(message: topPError)

                    Divider()
                        .padding(.vertical, 4)

                    Button {
                        // Restore defaults
                        keepAliveValue = defaultKeepAlive
                        timeoutValue = String(defaultTimeout)
                        numCtxValue = String(defaultNumCtx)
                        temperatureValue = String(defaultTemperature)
                        topKValue = String(defaultTopK)
                        topPValue = String(defaultTopP)

                        // Update preferences
                        storedKeepAlive = defaultKeepAlive
                        storedRequestTimeout = defaultTimeout
                        storedOptions.num_ctx = defaultNumCtx
                        storedOptions.temperature = defaultTemperature
                        storedOptions.top_k = defaultTopK
                        storedOptions.top_p = defaultTopP

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
        .onAppear {
            if let value = storedKeepAlive { keepAliveValue = value }
            if let value = storedOptions.num_ctx { numCtxValue = String(value) }
            if let value = storedOptions.temperature { temperatureValue = String(value) }
            if let value = storedOptions.top_p { topPValue = String(value) }
            if let value = storedOptions.top_k { topKValue = String(value) }
            if let value = storedRequestTimeout { timeoutValue = String(Int(value)) }
        }
    }
}

#Preview {
    LocalModelAdvancedOptionsView(storedStreamResponse: .constant(true),
                                  storedKeepAlive: .constant(nil),
                                  storedRequestTimeout: .constant(nil),
                                  storedOptions: .constant(LocalChatOptions()))
}
