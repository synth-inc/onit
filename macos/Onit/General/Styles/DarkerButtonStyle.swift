//
//  DarkerButtonStyle.swift
//  Onit
//
//  Created by Benjamin Sage on 10/8/24.
//

import SwiftUI

struct DarkerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}
