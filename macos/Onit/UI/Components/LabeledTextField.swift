//
//  LabeledTextField.swift
//  Onit
//
//  Created by Kévin Naudin on 05/02/2025.
//

import SwiftUI

struct LabeledTextField: View {
    let label: String
    @Binding var text: String

    var secure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.leading, 8)

            if secure {
                SecureField("", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .frame(height: 22)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .textFieldStyle(PlainTextFieldStyle())
            } else {
                TextField("", text: $text)
                    .textFieldStyle(.roundedBorder)
                    .frame(height: 22)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.primary)
                    .textFieldStyle(PlainTextFieldStyle())
            }
        }
    }
}

#Preview {
    LabeledTextField(label: "Title", text: .constant(""))
}
