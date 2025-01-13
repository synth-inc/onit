//
//  ModelsTab.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct ModelsTab: View {
    @Environment(\.model) var model
    
    var body: some View {
        ScrollView {
            RemoteModelsSection()
                .padding(.vertical, 20)
                .padding(.horizontal, 86)
        }
        .frame(maxWidth: 569)
    }
}

#Preview {
    ModelsTab()
}
