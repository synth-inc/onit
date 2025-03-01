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

            HStack {
                if prompt.isEditing {
                    TextField("Enter instruction", text: .init(
                        get: { prompt.currentInstruction },
                        set: { prompt.editingInstruction = $0 }
                    ))
                    .appFont(.medium14)
                    .textFieldStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Button("Send") {
                        prompt.finishEditing()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Cancel") {
                        prompt.cancelEditing()
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text(prompt.currentInstruction)
                        .appFont(.medium14)
                        .foregroundStyle(.FG)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        prompt.startEditing()
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.gray100)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
            .background(.gray800, in: .rect(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(.gray500)
            }
            .textSelection(.enabled)
        }
        .padding()
    }
}

#Preview {
    FinalContextView(isExpanded: true, prompt: .sample)
}
