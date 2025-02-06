//
//  ModelTitle.swift
//  Onit
//
//  Created by Benjamin Sage on 1/13/25.
//

import SwiftUI

struct ModelTitle: View {
    var title: String
    @Binding var isOn: Bool
    @Binding var showToggle: Bool

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 13))
            Spacer()
            if showToggle {
                Toggle("", isOn: $isOn)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
        }
    }
}
