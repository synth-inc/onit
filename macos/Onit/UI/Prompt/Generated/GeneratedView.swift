//
//  GeneratedView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI

struct GeneratedView: View {
    var result: String

    var body: some View {
        VStack(spacing: 16) {
            GeneratedContentView(result: result)
            GeneratedToolbar()
        }
        .padding(16)
    }
}

#Preview {
    GeneratedView(result: "Hey there, fabulous world!")
}
