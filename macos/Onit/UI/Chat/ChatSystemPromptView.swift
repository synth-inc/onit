//
//  ChatSystemPromptView.swift
//  Onit
//
//  Created by Kévin Naudin on 11/02/2025.
//

import SwiftUI

struct ChatSystemPromptView: View {
    @Environment(\.model) var model
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
                HStack(alignment: .center, spacing: 6) {
                    Image(.chatSettings)
                        .renderingMode(.template)
                    Text(systemPrompt.name)
                        .appFont(.medium14)
                        .lineLimit(1)
                    Image(.smallChevDown)
                        .renderingMode(.template)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.vertical, 2)
                .foregroundStyle(.blue300)
            }
            .buttonStyle(DarkerButtonStyle())
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Prompt")
                        .appFont(.medium14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.horizontal, .top], 8)
                    
                    ScrollView {
                        Text(systemPrompt.prompt)
                            .appFont(.medium14)
                            .foregroundStyle(.gray100)
                            .padding(.horizontal, 8)
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
                                        model.newChat(shouldSystemPrompt: true)
                                    }
                            }
                        }
                    }
                    .padding([.horizontal, .bottom], 8)
                }
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 1)
                        .fill(.gray600)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background {
            GeometryReader { g in
                Color.clear
                    .onAppear {
                        model.systemPromptHeight = g.size.height
                    }
                    .onChange(of: g.size.height) { _, new in
                        model.systemPromptHeight = new
                    }
                    .onDisappear {
                        model.systemPromptHeight = 0
                    }
            }
        }
    }
}

#Preview {
    ChatSystemPromptView(isExpanded: true, systemPrompt: SystemPrompt.outputOnly)
}
