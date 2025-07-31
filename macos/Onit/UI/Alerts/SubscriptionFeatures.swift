//
//  SubscriptionFeatures.swift
//  Onit
//
//  Created by Loyd Kim on 5/5/25.
//

import SwiftUI

struct SubscriptionFeatures: View {
    private let centerErrorText: Bool
    
    init(centerErrorText: Bool = false) {
        self.centerErrorText = centerErrorText
    }
    
    @State private var features: [SubscriptionFeature]?
    @State private var fetching: Bool = true
    @State private var errorMessage: String = ""
    
    var body: some View {
        HStack() {
            if fetching {
                shimmers
            } else if !errorMessage.isEmpty {
                Text(errorMessage)
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: Color.red500,
                        align: centerErrorText ? .center : .leading
                    )
            } else if let features = features {
                VStack(alignment: .leading, spacing: 9) {
                    ForEach(features) { feature in
                        Text(feature.name).styleText(size: 13, weight: .regular)
                    }
                }
            }
        }
        .task {
            await handleFetchSubscriptionFeatures()
        }
    }
}

// MARK: - Child Components

extension SubscriptionFeatures {
    private var shimmers: some View {
        VStack(alignment: .leading, spacing: 9) {
            Shimmer(width: 160, height: 16)
            Shimmer(width: 160, height: 16)
            Shimmer(width: 160, height: 16)
        }
    }
}

// MARK: - Private Functions

extension SubscriptionFeatures {
    private func handleFetchSubscriptionFeatures() async {
        do {
            errorMessage = ""
            fetching = true
            
            let client = FetchingClient()
            features = try await client.getSubscriptionFeatures()
            
            fetching = false
        } catch {
            errorMessage = error.localizedDescription
            fetching = false
        }
    }
}
