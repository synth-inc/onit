//
//  GeneratedContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import SwiftUI

struct GeneratedContentView: View {
    var result: String

    var body: some View {
        Text(result)
            .appFont(.medium16)
            .foregroundStyle(.FG)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
    
#Preview {
    GeneratedContentView(result: "Hello world")
}
