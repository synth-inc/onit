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

            Text("Add a new provider")
                .font(.headline)
                .padding(.bottom, 12)

            VStack(spacing: 16) {
                LabeledTextField(label: "Provider Name", text: $name)
                LabeledTextField(label: "URL", text: $baseURL)
                LabeledTextField(label: "Token", text: $token, secure: true)
            }

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Verify & Save") {
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
                    errorMessage = "A provider with this name already exists."
                    return
                }
                if AIModel.ModelProvider.allCases.contains(where: {
                    $0.rawValue.caseInsensitiveCompare(name) == .orderedSame
                }) {
                    errorMessage =
                        "Custom provider cannot have the same name as a built-in provider."
                    return
                }

                if containsVersionSegment(baseURL) {
                    errorMessage =
                        "The base URL should not include the API version or endpoint (for example, for OpenRouter, use 'https://openrouter.ai/api', not 'https://openrouter.ai/api/v1' or 'https://openrouter.ai/api/v1/models')."
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
                errorMessage = "Failed to fetch models: \(error.localizedDescription)"
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
