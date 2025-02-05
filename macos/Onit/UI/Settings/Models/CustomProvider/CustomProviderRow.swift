//
//  CustomProviderRow.swift
//  Onit
//
//  Created by Kévin Naudin on 05/02/2025.
//

import Defaults
import SwiftUI

struct CustomProviderRow: View {
    @Default(.availableRemoteModels) var availableRemoteModels
    @Default(.visibleModelIds) var visibleModelIds
    @Binding var provider: CustomProvider
    
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
                
//                Button(role: .destructive) {
//                    
//                    // TODO: KNA - Remove from visible also
//                    // Remove provider's models from available remote models
////                    Defaults[.availableRemoteModels].removeAll { model in
////                        model.customProvider?.id == provider.id
////                    }
//                    
//                } label: {
//                    Image(systemName: "trash")
//                }
            }
            
            if provider.isEnabled {
                GroupBox {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(providerModels, id: \.self) { model in
                            ModelToggle(aiModel: model)
                                .frame(height: 36)
                        }
                    }
                    .padding(.vertical, -4)
                    .padding(.horizontal, 4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .cornerRadius(8)
        .onChange(of: provider.isEnabled, initial: false) { old, new in
            let modelIds = Set(provider.models)

            if new {
                visibleModelIds.formUnion(modelIds)
            } else {
                visibleModelIds.subtract(modelIds)
            }
            
            print(visibleModelIds)
        }
    }
}

#Preview {
    CustomProviderRow(provider: .constant(PreviewSampleData.customProvider))
}
