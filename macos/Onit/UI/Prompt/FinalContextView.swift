//
//  FinalContextView.swift
//  Onit
//
//  Created by Benjamin Sage on 1/14/25.
//

import Defaults
import SwiftUI

struct FinalContextView: View {
    @Environment(\.windowState) var windowState
    @State var isContextListExpanded: Bool = false
    @State private var isEditing: Bool = false
    @State private var isHoveringInstruction: Bool = false
    @State private var isPressedInstruction: Bool = false
    
    @State private var cursorPosition: Int = 0

    let prompt: Prompt

    var usingContextOrInput: Bool {
        usingContext || prompt.input != nil
    }

    var usingContext: Bool {
        !prompt.contextList.isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            if isEditing {
                PromptCore(
                    placeholder: "",
                    text: Binding(
                        get: { prompt.instruction },
                        set: { prompt.instruction = $0 }
                    ),
                    onSubmit: { windowState.generate(prompt) },
                    onUnfocus: { isEditing = false },
                    cursorPosition: $cursorPosition,
                    detectLinks: false,
                    isEditing: true,
                    padding: 0
                )
            } else {
                staticPromptInstruction
            }
            
            if windowState.isSearchingWeb[prompt.id] ?? false {
                isSearchingWebShimmer
            } else if usingContextOrInput {
                finalContextToggleExpandButton

                if isContextListExpanded {
                    if let input = prompt.input {
                        InputView(input: input, isEditing: false)
                    }

                    if usingContext { finalContextList }
                }
            }
        }
        .padding(12)
    }
}

// MARK: - Child Components

extension FinalContextView {
    private var staticPromptInstruction: some View {
        ZStack() {
            Text(prompt.instruction)
                .frame(maxWidth: .infinity, alignment: .leading)
                .styleText()
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 13)
        .padding(.horizontal, 8)
        .background(isHoveringInstruction ? .gray800 : .gray900)
        .addBorder(cornerRadius: 8, lineWidth: 1.3)
        .overlay(alignment: .topTrailing) {
            Image(.edit)
                .resizable()
                .frame(width: 16, height: 16)
                .padding(4)
                .background(.gray500)
                .foregroundColor(.gray200)
                .cornerRadius(6)
                .padding(6)
                .opacity(isHoveringInstruction && !isEditing ? 1 : 0)
                .allowsHitTesting(false)
                .addAnimation(dependency: isHoveringInstruction)
        }
        .scaleEffect(isPressedInstruction ? 0.99 : 1)
        .addAnimation(dependency: isHoveringInstruction)
        .onHover{ isHovering in isHoveringInstruction = isHovering}
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressedInstruction = true }
                .onEnded { _ in
                    isPressedInstruction = false
                    isEditing = true
                }
        )
    }
    
    private var isSearchingWebShimmer: some View {
        HStack {
            Image(.web)
                .resizable()
                .frame(width: 16, height: 16)
                .padding(4)
                .foregroundColor(.gray200)
            Text("Searching the web")
                .appFont(.medium16)
                .foregroundColor(.gray200)
            Spacer()
        }
        .shimmering()
    }
    
    private var finalContextToggleExpandButton: some View {
        Button {
            isContextListExpanded.toggle()
        } label: {
            HStack(alignment: .center) {
                Image(.paperclipStars)
                Text("Final context used")
                    .appFont(.medium14)
                Image(.smallChevDown)
                    .renderingMode(.template)
                    .rotationEffect(
                        isContextListExpanded ? .degrees(180) : .degrees(0)
                    )
                Spacer()
            }
        }
        .foregroundStyle(.gray100)
        .buttonStyle(.plain)
    }
    
    private var finalContextList: some View {
        ContextList(
            contextList: prompt.contextList,
            direction: .vertical,
            onItemTap: { context in
                if context.isWebSearchContext, let url = context.webURL {
                    NSWorkspace.shared.open(url)
                } else {
                    ContextWindowsManager.shared.showContextWindow(
                        windowState: windowState,
                        context: context
                    )
                }
            }
        )
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(.clear)
                .strokeBorder(.gray700)
        }
    }
}

#Preview {
    FinalContextView(isContextListExpanded: true, prompt: .sample)
}
