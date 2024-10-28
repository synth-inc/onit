//
//  MenuIcon.swift
//  Onit
//
//  Created by Benjamin Sage on 10/22/24.
//

import SwiftUI
import Combine

struct MenuIcon: View {
    @Environment(\.model) var model

    var body: some View {
        Image(model.trusted ? .smirk : .untrusted)
            .renderingMode(model.trusted ? .template : .original)
            .animation(.default, value: model.trusted)
    }
}

#Preview {
    ModelContainerPreview {
        MenuIcon()
    }
}
