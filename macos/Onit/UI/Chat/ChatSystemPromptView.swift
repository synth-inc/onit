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
            HStack(alignment: .center, spacing: 6) {
                Image(.chatSettings)
                    .renderingMode(.template)
                Text(systemPrompt.name)
                    .lineLimit(1)
                Button {
                    isExpanded.toggle()
                } label: {
                    Image(.smallChevDown)
                        .renderingMode(.template)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .buttonStyle(DarkerButtonStyle())
            }
            .foregroundStyle(.blue300)
            
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Text("System Prompt")
                        //.appFont(.medium14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding([.horizontal, .top], 8)
                    
                    ScrollView {
                        Text(systemPrompt.prompt)
                            .foregroundStyle(.gray100)
                            .padding(.horizontal, 8)
                    }
                    .frame(minHeight: 0, maxHeight: 165, alignment: .top)
                    
                    PromptDivider()
                    
                    HStack(alignment: .top, spacing: 4) {
                        Image(systemName: "info.circle")
                            .frame(width: 16, height: 16)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(infoFirstLine)
                                .foregroundStyle(.white.opacity(0.5))
                            
                            HStack(spacing: 0) {
                                Text(infoSecondLinePrefix)
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                Text(infoClickableText)
                                    .foregroundStyle(.blue300)
                                    .underline()
                                    .onTapGesture {
                                        model.newChat()
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
