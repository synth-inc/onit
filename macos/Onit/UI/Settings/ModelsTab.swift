//
//  ModelsTab.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct ModelsTab: View {
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                OfflineText()
                
                VStack(spacing: 25) {
                    RemoteModelsSection()
                    LocalModelsSection()
                    DefaultModelsSection()
                }
            }
            .padding()
            .padding(.horizontal, 86)
        }
    }
}

#Preview {
    ModelsTab()
}
