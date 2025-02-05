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
    
    @State private var searchText: String = ""
    
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
                        .frame(maxHeight: 5 * 36) // Limit to 5 rows
                    }
                }
            }
        }
        .cornerRadius(8)
    }
}

#Preview {
    CustomProviderRow(provider: .constant(PreviewSampleData.customProvider))
}
