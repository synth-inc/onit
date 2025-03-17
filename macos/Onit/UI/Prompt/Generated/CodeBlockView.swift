//
//  CodeBlockView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/28/24.
//

import HighlightSwift
import MarkdownUI
import SwiftUI

struct CodeBlockView: View {
    @Environment(\.model) var model
    
    var configuration: CodeBlockConfiguration?
    var content: String {
        configuration?.content ?? ""
    }
    
    var prompt: (Prompt, Bool)? {
        for prompt in model.currentPrompts ?? [] {
            if let response = prompt.responses.first(where: {
                let promptText = $0.text
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                let content = content
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                
                return promptText.contains(content)
            }) {
                return (prompt, response.isPartial)
            }
        }
        
        return nil
    }
    
    private var notepadOldText: String {
        guard let (prompt, _) = prompt else { return "" }
        
        let autoContexts = prompt.contextList.autoContexts
        
        if let input = prompt.input {
            print("CodeBlockView notepadOldText : \(input.selectedText)")
            return input.selectedText
        } else if !autoContexts.isEmpty {
            print("CodeBlockView notepadOldText : \(autoContexts.values.joined(separator: "\n"))")
            return autoContexts.values.joined(separator: "\n")
        }
        
        return ""
    }
    
    private var notepadNewText: String {
        print("CodeBlockView notepadNewText : \(configuration?.content ?? "")")
        return configuration?.content ?? ""
    }
    
    private var notepadIsStreaming: Bool {
        guard let (_, isStreaming) = prompt else { return false }
        
        return isStreaming
    }

    var rect: RoundedRectangle {
        .rect(cornerRadius: 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            top

            Color.gray700
                .frame(height: 1)

            bottom
        }
        .overlay {
            rect
                .strokeBorder(.gray700)
        }
        .clipShape(rect)
    }

    var top: some View {
        HStack {
            if let language = configuration?.language {
                Text(language)
                    .appFont(.medium13)
            }

            Spacer()
            
            notepadButton
            copyButton
        }
        .foregroundStyle(.gray100)
        .padding(.vertical, 2)
        .padding(.leading, 12)
        .padding(.trailing, 8)
    }
    
    var notepadButton: some View {
        Button(action: {
            NotepadWindowController.shared.showWindow(
                oldText: notepadOldText,
                newText: notepadNewText,
                isStreaming: notepadIsStreaming
            )
        }) {
            Image(.notes)
        }
        .tooltip(prompt: "Notepad")
    }

    var copyButton: some View {
        CopyButton(text: content)
    }

    var bottom: some View {
        ViewThatFits(in: .vertical) {
            ScrollView(.horizontal) {
                textView
            }
            ScrollView([.horizontal, .vertical]) {
                textView
            }
        }
        .frame(maxHeight: 150)
    }

    @ViewBuilder
    var textView: some View {
        ZStack(alignment: .topLeading) {
            Spacer()
                .containerRelativeFrame(.horizontal)

            Group {
                if let language = configuration?.language,
                    let language = HighlightLanguage.language(for: language)
                {
                    CodeText(content)
                        .codeFont(AppFont.code.nsFont)
                        .highlightLanguage(language)
                } else {
                    CodeText(content)
                }
            }
            .environment(\.colorScheme, .dark)
            .padding(.bottom, 10)
            .padding(.horizontal, 10)
            .padding(.top, 12)
        }
    }
}

#Preview {
    CodeBlockView(configuration: nil)
}
