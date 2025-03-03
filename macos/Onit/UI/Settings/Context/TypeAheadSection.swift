//
//  TypeAheadSection.swift
//  Onit
//
//  Created by Kévin Naudin on 20/02/2025.
//

import Defaults
import SwiftUI

struct TypeAheadSection: View {
    
    @Default(.availableLocalModels) var availableLocalModels
    @Default(.typeaheadConfig) var typeaheadConfig
    
    @State private var currentDate = Date()
    
    private var enableBinding: Binding<Bool> {
        Binding {
            guard typeaheadConfig.isEnabled else { return false }
            guard let resumeAt = typeaheadConfig.resumeAt else { return true }
            
            return currentDate >= resumeAt
        } set: { newValue in
            typeaheadConfig.isEnabled = newValue
            typeaheadConfig.resumeAt = nil
        }
    }
    private var resumeAt: String {
        guard let resumeAt = typeaheadConfig.resumeAt,
              resumeAt > currentDate else {
            return ""
        }
        
        return timeString(from: resumeAt.timeIntervalSince(currentDate))
    }
    
    var body: some View {
        Section {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Type Ahead")
                        .font(.system(size: 13))
                    Spacer()
                    Toggle("", isOn: enableBinding)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                    SettingInfoButton(
                        title: "Auto-Context, Type ahead",
                        description:
                            "When enabled, Onit will read the input's text from the foregrounded application and will suggest autocompletions based on that text. No context is ever uploaded.",
                        defaultValue: "on",
                        valueType: "Bool"
                    )
                }
                HStack {
                    Text("Display typeahead anywhere")
                        .font(.system(size: 12))
                        .foregroundStyle(.gray200)
                    Spacer()
                    Text(resumeAt)
                        .font(.system(size: 12))
                        .foregroundStyle(.gray200)
                }
            }
            if typeaheadConfig.isEnabled {
                modelSelection
                
                if !typeaheadConfig.excludedApps.isEmpty {
                    excludedApps
                }
            }
//                    KeyboardShortcuts.Recorder(
//                        "Shortcut", name: .launchWithAutoContext
//                    )
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                Task { @MainActor in
                    self.currentDate = Date()
                }
            }
        }
    }
    
    private var modelSelection: some View {
        VStack(alignment: .leading) {
            Text("Model used")
                .font(.system(size: 13))
            GroupBox {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(availableLocalModels, id: \.self) { model in
                        Toggle(isOn: Binding(get: {
                            return model == typeaheadConfig.model
                        }, set: { isOn in
                            typeaheadConfig.model = isOn ? model : nil
                        })) {
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
            LocalModelAdvancedOptionsView(storedStreamResponse: $typeaheadConfig.streamResponse,
                                          storedKeepAlive: $typeaheadConfig.keepAlive,
                                          storedRequestTimeout: $typeaheadConfig.requestTimeout,
                                          storedOptions: $typeaheadConfig.options,
                                          streamAdditionalInfo: "If enabled, Onit streams partial responses from model providers, offering quicker auto complete suggestions.")
        }
    }
    
    private var excludedApps: some View {
        VStack(alignment: .leading) {
            Text("Excluded Applications")
                .font(.system(size: 13))

            GroupBox {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(typeaheadConfig.excludedApps.sorted()), id: \.self) { app in
                        HStack(alignment: .center) {
                            Text(app)
                            Spacer()
                            Button(action: {
                                typeaheadConfig.excludedApps.remove(app)
                            }) {
                                Image(.bin)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(.borderless)
                        }
                        .frame(height: 36)
                        //.padding(.vertical, 4)
                    }
                }
                .padding(.vertical, -4)
                .padding(.horizontal, 4)
            }
        }
    }
    
    private func timeString(from interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        
        return "Paused for \(minutes) min, \(seconds) sec"
    }
}

#Preview {
    TypeAheadSection()
}
