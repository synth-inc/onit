//
//  InputBody.swift
//  Onit
//
//  Created by Benjamin Sage on 10/3/24.
//

import SwiftUI

struct InputBody: View {
    @Environment(\.model) var model

    var text: String

    @State var textHeight: CGFloat = 0

    var height: CGFloat {
        min(textHeight, 73)
    }

    var body: some View {
        ViewThatFits(in: .vertical) {
            textView
            ScrollView {
                textView
            }
        }
        .frame(height: model.inputExpanded ? height : 0)
    }

    var textView: some View {
        Text(text.trimmingCharacters(in: .whitespacesAndNewlines))
            .foregroundStyle(.white)
            .appFont(.medium16)
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            textHeight = proxy.size.height
                        }
                }
            }
    }
}

#if DEBUG
#Preview {
    ModelContainerPreview {
        InputBody(text: "This is a long sample string")
    }
}
#endif
