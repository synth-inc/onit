//
//  GeneratedContentView.swift
//  Onit
//
//  Created by Benjamin Sage on 10/2/24.
//

import Defaults
import Foundation
import MarkdownUI
import SwiftUI
import KeyboardShortcuts

struct GeneratedContentView: View {
    @Environment(\.model) var model

    var prompt: Prompt
    
    var isPartial: Bool {
        let response = prompt.responses[prompt.generationIndex]
        
        return response.isPartial
    }
    
    var textToRead: String {
        let response = prompt.responses[prompt.generationIndex]
        
        return response.isPartial ? model.streamedResponse : response.text
    }
    
    var body: some View {

        VStack(alignment: .leading) {
            ParsedContentView(text: textToRead)
                .padding(.horizontal, 16)
            Spacer()
            if textToRead.isEmpty {
                HStack {
                    Spacer()
                    QLImage("loader_rotated-200")
                        .frame(width: 36, height: 36)
                        .padding(.horizontal, 16)
                    Spacer()
                }
            }
            if isPartial {
                HStack {
                    Spacer()
                    Text(cancelText)
                        .foregroundStyle(.gray200)
                        .appFont(.medium13)
                        .underline()
                        .onTapGesture {
                            model.cancelGenerate()
                            model.textFocusTrigger.toggle()
                        }
                        .onHover { isHovering in
                            if isHovering {
                                NSCursor.pointingHand.push()
                            } else {
                                NSCursor.pop()
                            }
                        }
                    Spacer()
                }
            }
        }
    }
    
    var cancelText: String {
        if let keyboardShortcutString = KeyboardShortcuts.getShortcut(for: .cancelGeneration)?
            .description
        {
            "Cancel Generation " + keyboardShortcutString
        } else {
            "Cancel Generation"
        }
    }
    
}

extension Theme {
    @MainActor static var custom: Theme {
        @Default(.fontSize) var fontSize
        @Default(.lineHeight) var lineHeight
        
        return Theme()
            .text {
                FontFamily(.custom("Inter"))
                FontSize(fontSize)
                ForegroundColor(.FG)
            }
            .code {
                FontFamily(.custom("SometypeMono"))
                FontFamilyVariant(.monospaced)
                FontSize(fontSize)
                ForegroundColor(.pink)
            }
            .codeBlock { configuration in
                CodeBlockView(configuration: configuration)
            }
            .paragraph { configuration in
                configuration.label
                    .markdownMargin(top: fontSize + (lineHeight * fontSize) - fontSize) // This works
            }
    }
}



#Preview {
    GeneratedContentView(prompt: Prompt.sample)
}

// MARK: - Parsed Content and Thought Process Views

struct ParsedContentView: View {
    let text: String
    
    @Default(.lineHeight) var lineHeight
    @Default(.fontSize) var fontSize
    
    // ContentSegment represents either normal text or a thought block
    struct ContentSegment {
        let isThought: Bool
        let isStreaming: Bool
        let content: String
    }
    
    // Split the text into segments based on <think> and </think> tags.
    var segments: [ContentSegment] {
        var result: [ContentSegment] = []
        var currentIndex = text.startIndex
        
        while let openRange = text.range(of: "<think>", range: currentIndex..<text.endIndex) {
            // Add normal text before <think> if any
            let normalText = String(text[currentIndex..<openRange.lowerBound])
            if !normalText.isEmpty {
                result.append(ContentSegment(isThought: false, isStreaming: false, content: normalText))
            }
            
            let searchStart = openRange.upperBound
            if let closeRange = text.range(of: "</think>", range: searchStart..<text.endIndex) {
                // Found closing tag: complete thought block
                let thoughtContent = String(text[searchStart..<closeRange.lowerBound])
                result.append(ContentSegment(isThought: true, isStreaming: false, content: thoughtContent))
                currentIndex = closeRange.upperBound
            } else {
                // No closing tag found: streaming thought block
                let thoughtContent = String(text[searchStart..<text.endIndex])
                result.append(ContentSegment(isThought: true, isStreaming: true, content: thoughtContent))
                currentIndex = text.endIndex
            }
        }
        
        if currentIndex < text.endIndex {
            let remaining = String(text[currentIndex..<text.endIndex])
            if !remaining.isEmpty {
                result.append(ContentSegment(isThought: false, isStreaming: false, content: remaining))
            }
        }
        return result
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(segments.enumerated()), id: \ .offset) { index, segment in
                if segment.isThought {
                    ThoughtProcessView(content: segment.content, streaming: segment.isStreaming)
                } else {
                    Markdown(segment.content)
                        .markdownTheme(.custom)
                        .textSelection(.enabled)
                        .lineSpacing((lineHeight * fontSize) - fontSize)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct ThoughtProcessView: View {
    let content: String
    let streaming: Bool
    
    @Default(.lineHeight) var lineHeight
    @Default(.fontSize) var fontSize
    @State private var isExpanded: Bool = false
    
    var title: String {
        streaming ? "Thinking..." : "Thought-process"
    }
    
    var arrowImageName: String {
        isExpanded ? "chevron.up" : "chevron.down"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(.lightBulb)
                Text(title)
                    .font(.headline)
                    .shimmering(active: streaming)
                Spacer()
                Image(systemName: arrowImageName)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Only allow expanding if the thought block is complete
                if !streaming {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }
            }
            
            if isExpanded && !streaming {
                Text(content)
                    .padding(.leading, 20)
                    .lineSpacing((lineHeight * fontSize) - fontSize)
            }
        }
        .padding(8)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}
