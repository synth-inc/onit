//
//  MenuAppearsInPicker.swift
//  Onit
//
//  Created by Benjamin Sage on 10/1/24.
//

import SwiftUI

struct MenuAppearsInPicker: View {
    var body: some View {
        MenuBarRow {

        } leading: {
            HStack(spacing: 4) {
                Image(.textQuotations)
                    .resizable()
                    .scaledToFit()
                    .padding(1.5)
                    .frame(width: 16, height: 16)
                Text("Appear in Text Fields")
            }
            .padding(.leading, 5)
        } trailing: {
            Image(.chevRight)
                .renderingMode(.template)
                .foregroundStyle(.black)
        }
    }
}

#Preview {
    MenuAppearsInPicker()
}
