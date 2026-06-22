//
//  CustomProviderFormView.swift
//  Onit
//
//  Created by Kévin Naudin on 05/02/2025.
//

import Defaults
import SwiftUI

struct CustomProviderFormView: View {
    @Environment(\.dismiss) private var dismiss

    @Default(.availableCustomProviders) var availableCustomProviders
    @Default(.availableRemoteModels) var availableRemoteModels

    @State var name: String = ""
    @State var baseURL: String = ""
    @State var token: String = ""

    @Binding var isSubmitted: Bool

    @State private var errorMessage: String?

    var body: some View {
        Form {

            Text(String.localized("Add a new provider", table: "Models"))
                .font(.headline)
                .padding(.bottom, 12)

            VStack(spacing: 16) {
                LabeledTextField(label: String.localized("Provider Name", table: "Models"), text: $name)
                LabeledTextField(label: String.localized("URL", table: "Models"), text: $baseURL)
                LabeledTextField(label: String.localized("Token", table: "Models"), text: $token, secure: true)
            }

            HStack {
                Spacer()

                Button(String.localized("Cancel", table: "Models")) {
                    dismiss()
                }

                Button(String.localized("Verify & Save", table: "Models")) {
                    errorMessage = nil
                    addProvider()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(name.isEmpty || baseURL.isEmpty || token.isEmpty)
            }.padding(.top, 8)

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(Color.red500)
            }
        }
        .padding()
        .frame(width: 330)
    }

    private func addProvider() {
        Task {
            do {
                // Check for duplicate provider name
                if availableCustomProviders.contains(where: { $0.name == name }) {
                    errorMessage = String.localized("A provider with this name already exists.", table: "Models")
                    return
                }
                if AIModel.ModelProvider.allCases.contains(where: {
                    $0.rawValue.caseInsensitiveCompare(name) == .orderedSame
                }) {
                    errorMessage =
                        String.localized("Custom provider cannot have the same name as a built-in provider.", table: "Models")
                    return
                }

                if containsVersionSegment(baseURL) {
                    errorMessage =
                        String.localized("The base URL should not include the API version or endpoint (for example, for OpenRouter, use 'https://openrouter.ai/api', not 'https://openrouter.ai/api/v1' or 'https://openrouter.ai/api/v1/models').", table: "Models")
                    return
                }

                let provider = CustomProvider(
                    name: name,
                    baseURL: baseURL,
                    token: token,
                    models: []
                )
                try await provider.fetchModels()

                // If the above doesn't crash, we're good!
                provider.isTokenValidated = true
                availableCustomProviders.append(provider)
                availableRemoteModels.append(contentsOf: provider.models)
                DispatchQueue.main.async {
                    isSubmitted = true
                    dismiss()
                }
            } catch {
                errorMessage = String(format: String.localized("Failed to fetch models: %@", table: "Models"), error.localizedDescription)
            }
        }
    }

    private func containsVersionSegment(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        let path = url.path.lowercased()
        return path.range(of: #"\/v\d+"#, options: .regularExpression) != nil
    }
}

#Preview {
    CustomProviderFormView(isSubmitted: .constant(false))
}
