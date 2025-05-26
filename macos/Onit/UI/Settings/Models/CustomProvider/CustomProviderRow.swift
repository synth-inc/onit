//
//  CustomProviderRow.swift
//  Onit
//
//  Created by Kévin Naudin on 05/02/2025.
//

import Defaults
import SwiftUI

struct CustomProviderRow: View {
    @Default(.availableCustomProviders) var availableCustomProviders
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.visibleModelIds) var visibleModelIds
    @Default(.streamResponse) var streamResponse
    @Binding var provider: CustomProvider

    @State private var searchText: String = ""
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var showAlert = false
    @State private var showAdvanced: Bool = false
    
    private var streamResponseBinding: Binding<Bool> {
        Binding {
            streamResponse.customProviders[provider.id] ?? false
        } set: { newValue in
            streamResponse.customProviders[provider.id] = newValue
        }
    }

    private var filteredProviderModels: [AIModel] {
        providerModels.filter { model in
            searchText.isEmpty || model.displayName.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var providerModels: [AIModel] {
        availableRemoteModels.filter { $0.customProviderName == provider.name }
    }

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(provider.name)
                    .font(.system(size: 13))
                Spacer()

                Toggle("", isOn: $provider.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.small)

                Button(action: {
                    showAlert = true
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .alert(isPresented: $showAlert) {
                    Alert(
                        title: Text("Remove Provider"),
                        message: Text("Are you sure you want to remove this provider?"),
                        primaryButton: .destructive(Text("Remove")) {
                            removeProvider()
                        },
                        secondaryButton: .cancel()
                    )
                }
            }

            tokenField
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }

            if provider.isEnabled {
                GroupBox {
                    VStack {
                        TextField("Search models", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding(.horizontal, 4)

                        ScrollView {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(filteredProviderModels, id: \.self) { model in
                                    ModelToggle(aiModel: model)
                                        .frame(height: 36)
                                }
                            }
                            .padding(.vertical, -4)
                            .padding(.horizontal, 4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 5 * 36)  // Limit to 5 rows
                    }
                }
                advancedSettings
            }
        }
        .cornerRadius(8)
    }

    var tokenField: some View {
        HStack(spacing: 7) {
            TextField("Enter your \(provider.name) API key", text: $provider.token)
                .textFieldStyle(.roundedBorder)
                .frame(height: 22)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.primary)  // Ensure placeholder text is not dimmed

            Button {
                loading = true
                
                Task {
                    await TokenValidationManager.shared.validateToken(provider: .custom, token: provider.token)
                    
                    DispatchQueue.main.async {
                        if provider.isTokenValidated {
                            errorMessage = nil
                        } else {
                            errorMessage = "Failed to validate token"
                        }
                        loading = false
                    }
                }
            } label: {
                if provider.isTokenValidated {
                    Text("Verified")
                } else {
                    if loading {
                        ProgressView()
                            .controlSize(.small)
                    } else {
                        Text("Verify →")
                    }
                }
            }
            .disabled(loading)
            .foregroundStyle(.white)
            .buttonStyle(.borderedProminent)
            .frame(height: 22)
            .fontWeight(.regular)
        }
    }
    
    var advancedSettings: some View {
        DisclosureGroup("Advanced", isExpanded: $showAdvanced) {
            StreamingToggle(isOn: streamResponseBinding)
                .padding(.leading, 8)
                .padding(.top, 4)
        }
    }

    private func removeProvider() {
        let modelsToRemove = availableRemoteModels.filter { $0.customProviderName == provider.name }
        availableRemoteModels.removeAll(where: { modelsToRemove.contains($0) })

        let modelsToRemoveUniqueIDs = modelsToRemove.map { $0.uniqueId }
        visibleModelIds.subtract(modelsToRemoveUniqueIDs)

        if let index = availableCustomProviders.firstIndex(where: { $0.name == provider.name }) {
            availableCustomProviders.remove(at: index)
        }
    }
}

//#Preview {
//    CustomProviderRow(provider: .constant(PreviewSampleData.customProvider))
//}
