//
//  QuickEditResponseView.swift
//  Onit
//
//  Created by Kévin Naudin on 10/06/2025.
//

import SwiftUI
import Defaults
import LLMStream

struct ViewOffsetKey: @preconcurrency PreferenceKey {
    typealias Value = CGFloat
    @MainActor static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct QuickEditResponseView: View {
    @Environment(\.windowState) private var state
    @Environment(\.openURL) var openURL
        
    @State private var previousViewOffset: CGFloat = 0
    @State private var hasUserManuallyScrolled: Bool = false
    @State private var isAutoScrolling: Bool = false
    @State private var lastAutoScrollTime: Date = Date.distantPast
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isButtonScrolling: Bool = false
    
    @Default(.fontSize) var fontSize
    @Default(.lineHeight) var lineHeight
    
    private let minimumOffset: CGFloat = 16
    private let autoScrollThrottleInterval: TimeInterval = 0.03
    
    let prompt: Prompt
    let isEditableElement: Bool
    
    var insertShortcut: KeyboardShortcut {
        .init(.return, modifiers: [.command])
    }
    
    init(prompt: Prompt, isEditableElement: Bool = false) {
        self.prompt = prompt
        self.isEditableElement = isEditableElement
    }
    
    private var textToDisplay: String {
        guard let state = state else { return "" }
        guard !prompt.responses.isEmpty else {
            return state.streamedResponse
        }
        
        let response = prompt.sortedResponses[prompt.generationIndex]
        return response.isPartial ? state.streamedResponse : response.text
    }
    
    private var configuration: LLMStreamConfiguration {
        let font = FontConfiguration(size: fontSize, lineHeight: lineHeight)
        let color = ColorConfiguration(citationBackgroundColor: .gray600,
                                       citationHoverBackgroundColor: .gray400,
                                       citationTextColor: .gray100)
        let thought = ThoughtConfiguration(icon: Image(.lightBulb))
        
        return LLMStreamConfiguration(font: font, colors: color, thought: thought)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            promptSection
            
            responseSection
            
            if prompt.generationState == .done {
                generatedToolbar
            }
        }
        .padding(.horizontal, 8)
    }
}

// MARK: - Components

extension QuickEditResponseView {
    
    private var promptSection: some View {
        Text(prompt.instruction)
            .appFont(.medium13)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity, minHeight: 24, alignment: .leading)
            .padding(8)
            .background(.gray700)
            .addBorder(cornerRadius: 8, lineWidth: 1, stroke: .gray500)
    }
    
    private var responseSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch prompt.generationState {
            case .generating:
                HStack(spacing: 8) {
                    LoaderPulse()
                        .frame(width: 16, height: 16)
                    
                    Text("Generating...")
                        .appFont(.medium13)
                        .foregroundColor(.gray300)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                
            case .streaming, .done:
                if textToDisplay.isEmpty && !(state?.isSearchingWeb[prompt.id] ?? false) {
                    HStack {
                        Spacer()
                        QLImage("loader_rotated-200")
                            .frame(width: 36, height: 36)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                } else {
                    ZStack(alignment: .bottom) {
                        scrollView
                        
                        if hasUserManuallyScrolled {
                            HStack {
                                Spacer()
                                IconButton(
                                    icon: .arrowDown,
                                    buttonSize: 36,
                                    activeColor: .white,
                                    inactiveColor: .white,
                                    hoverBackground: .gray400,
                                    tooltipPrompt: "Scroll to bottom"
                                ) {
                                    hasUserManuallyScrolled = false
                                    isButtonScrolling = true
                                    
                                    if let proxy = scrollProxy {
                                        withAnimation(.easeOut(duration: 0.2)) {
                                            proxy.scrollTo("bottom", anchor: .bottom)
                                        }
                                        
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                            isButtonScrolling = false
                                        }
                                    }
                                }
                                .background(.gray600)
                                .addBorder(cornerRadius: 18, stroke: .gray400)
                                .transition(.scale.combined(with: .opacity))
                                .padding(.trailing, 20)
                            }
                            .padding(.bottom, 4)
                        }
                    }
                }
                
            default:
                EmptyView()
            }
        }
    }
    
    private var scrollView: some View {
        // By reading fontSize and lineHeight here, we ensure SwiftUI observes them.
        
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    LLMStreamView(
                        text: textToDisplay,
                        configuration: configuration,
                        onUrlClicked: onUrlClicked,
                        onCodeAction: codeAction)
                    .id("\(fontSize)-\(lineHeight)") // Force recreation when font settings change
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
                    .id("content")
                    
                    Color.clear
                    .frame(height: 1)
                    .id("bottom")
                }
                .background(
                    GeometryReader {
                        Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                    }
                )
                .onPreferenceChange(ViewOffsetKey.self) { currentOffset in
                    MainActor.assumeIsolated {
                        guard !isAutoScrolling && !isButtonScrolling else { return }
                        
                        let offsetDifference: CGFloat = abs(previousViewOffset - currentOffset)
                        
                        if offsetDifference > minimumOffset {
                            if previousViewOffset > currentOffset {
                                hasUserManuallyScrolled = true
                            } else if previousViewOffset < currentOffset {
                                if offsetDifference > 50 {
                                    hasUserManuallyScrolled = true
                                }
                            }
                            
                            previousViewOffset = currentOffset
                        }
                    }
                }
            }
            .coordinateSpace(name: "scroll")
            .frame(maxHeight: 340)
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: textToDisplay) { oldValue, newValue in
                if newValue.count > oldValue.count &&
                    prompt.generationState == .streaming &&
                    !hasUserManuallyScrolled {
                    
                    let now = Date()
                    let timeSinceLastScroll = now.timeIntervalSince(lastAutoScrollTime)
                    
                    if timeSinceLastScroll >= autoScrollThrottleInterval && !isAutoScrolling {
                        lastAutoScrollTime = now
                        isAutoScrolling = true
                        
                        withAnimation(.easeOut(duration: 0.03)) {
                            proxy.scrollTo("bottom", anchor: .bottom)
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
                            isAutoScrolling = false
                        }
                    }
                }
            }
        }
        .mask(
            VStack(spacing: 0) {
                LinearGradient(
                    gradient: Gradient(colors: [Color.clear, Color.white]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
                
                Color.white
                
                LinearGradient(
                    gradient: Gradient(colors: [Color.white, Color.clear]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 20)
            }
        )
    }
    
    private var generatedToolbar: some View {
        HStack(spacing: 8) {
            if let generation = prompt.generation {
                if isEditableElement {
                    Button(
                        action: {
                            insertGeneratedText(generation)
                        },
                        label: {
                            HStack {
                                KeyboardShortcutView(shortcut: insertShortcut)
                                Text("Insert")
                            }
                            .padding(.horizontal, 8)
                        }
                    )
                    .buttonStyle(.plain)
                    .frame(height: 24)
                    .background(.blue400)
                    .clipShape(RoundedRectangle(cornerRadius: 5))
                }
                
                CopyButton(text: generation, stripMarkdown: true)
            }
            
            IconButton(
                icon: .arrowsSpin,
                tooltipPrompt: "Retry"
            ) {
                if let state = state {
                    state.generate(prompt)
                }
            }
        }
    }
}

// MARK: - Actions

extension QuickEditResponseView {
    
    private func onUrlClicked(urlString: String) {
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
    
    private func codeAction(code: String) {
        // TODO: Implement code action if needed
    }
    
    private func insertGeneratedText(_ text: String) {
        QuickEditManager.shared.activateLastApp()
        
        let textToInsert = text.stripMarkdown()
        let source = CGEventSource(stateID: .hidSystemState)
        let pasteDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        let pasteUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        
        pasteDown?.flags = .maskCommand
        pasteUp?.flags = .maskCommand
        
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(textToInsert, forType: .string)
        
        pasteDown?.post(tap: .cghidEventTap)
        pasteUp?.post(tap: .cghidEventTap)
    }
}

#Preview {
    QuickEditResponseView(prompt: Prompt.sample, isEditableElement: true)
        .background(.black)
}
