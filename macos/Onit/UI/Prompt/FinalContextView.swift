//
//  FinalContextView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import SwiftUI

struct FinalContextView: View {
    @State var isExpanded: Bool = true

    let prompt: Prompt

    var usingContextOrInput: Bool {
        usingContext || prompt.input != nil
    }

    var usingContext: Bool {
        !prompt.contextList.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if usingContextOrInput {
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(alignment: .center) {
                        Image(.paperclipStars)
                        Text("Final context used")
                            .appFont(.medium14)
                        Image(.smallChevDown)
                            .renderingMode(.template)
                            .rotationEffect(isExpanded ? .degrees(180) : .degrees(0))
                        Spacer()
                    }
                }
                .foregroundStyle(.gray100)
                .buttonStyle(.plain)

                if isExpanded {
                    if let input = prompt.input {
                        InputView(input: input, isEditing: false)
                    }

                    if usingContext {
                        ContextList(contextList: prompt.contextList, direction: .vertical)
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(.clear)
                                    .strokeBorder(.gray700)
                            }
                    }
                }
            }

            Text(prompt.instruction)
                .appFont(.medium14)
                .foregroundStyle(.FG)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(.gray800, in: .rect(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(.gray500)
                }
        }
        .padding()
    }
}

#Preview {
    FinalContextView(isExpanded: true, prompt: .sample)
}
