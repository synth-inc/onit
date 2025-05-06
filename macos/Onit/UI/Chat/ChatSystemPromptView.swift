//
//  ChatSystemPromptView.swift
//  Onit
//
//  Created by Kévin Naudin on 11/02/2025.
//

import SwiftUI

struct ChatSystemPromptView: View {
    @Environment(\.windowState) private var state
    
    @State var isExpanded: Bool = false
    @State private var contentHeight: CGFloat = 0
    
    var systemPrompt: SystemPrompt
    
    private let infoFirstLine = "You can use one system prompt per chat."
    private let infoSecondLinePrefix = "To change system prompt, "
    private let infoClickableText = "start a new chat->"
    
    private var infoAttributedString: AttributedString {
        var attributedString = AttributedString(infoFirstLine + "\n" + infoSecondLinePrefix + infoClickableText)

        if let range = attributedString.range(of: infoClickableText) {
            attributedString[range].foregroundColor = .blue300
            attributedString[range].underlineStyle = .single
        }
        
        return attributedString
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Button {
                withAnimation {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .top, spacing: 6) {
                    Image(.chatSettings)
                        .renderingMode(.template)
                    Text(systemPrompt.name)
                        .appFont(.medium14)
                        .lineLimit(1)
                    Image(.smallChevDown)
                        .renderingMode(.template)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 0)
                .foregroundStyle(.blue300)
            }
            .buttonStyle(DarkerButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text("System Prompt")
                        .appFont(.medium14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.horizontal, .top], 12)
                    
                    ScrollView {
                        Text(systemPrompt.prompt)
                            .appFont(.medium14)
                            .foregroundStyle(.gray100)
                            .padding(.horizontal, 12)
                            .background(
                                GeometryReader { geometry in
                                    Color.clear
                                        .onAppear {
                                            contentHeight = geometry.size.height
                                        }
                                        .onChange(of: geometry.frame(in: .local).height) { _, newHeight in
                                            contentHeight = newHeight
                                        }
                                }
                            )
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .frame(height: min(contentHeight, 165))
                    
                    PromptDivider()
                    
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "info.circle")
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(infoFirstLine)
                                .appFont(.medium13)
                                .foregroundStyle(.white.opacity(0.5))
                            
                            HStack(spacing: 0) {
                                Text(infoSecondLinePrefix)
                                    .appFont(.medium13)
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                Text(infoClickableText)
                                    .appFont(.medium13)
                                    .foregroundStyle(.blue300)
                                    .underline()
                                    .onTapGesture {
                                        state.newChat(shouldSystemPrompt: true)
                                    }
                            }
                        }
                    }
                    .padding([.horizontal, .bottom], 12)
                }
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1)
                        .fill(.gray600)
                }
            }
        }
        .padding(.top, 8)
        .padding(.horizontal, 12)
        .padding(.bottom, 0)
        .background {
            GeometryReader { g in
                Color.clear
                    .onAppear {
                        state.systemPromptHeight = g.size.height
                    }
                    .onChange(of: g.size.height) { _, new in
                        state.systemPromptHeight = new
                    }
                    .onDisappear {
                        state.systemPromptHeight = 0
                    }
            }
        }
    }
}

#Preview {
    ChatSystemPromptView(isExpanded: true, systemPrompt: SystemPrompt.outputOnly)
}
