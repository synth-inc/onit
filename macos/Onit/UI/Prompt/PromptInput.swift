//
//  PromptInput.swift
//  Onit
//
//  Created by Loyd Kim on 4/16/25.
//

import SwiftUI

struct PromptInput: View {
    @Environment(\.windowState) private var state
    
    private var detectLinks: Bool = true // TODO remove this once we use PromptInput for prompt editing
    
    private var maxLines: Int
    init(maxLines: Int = 6) { self.maxLines = maxLines }
    
    @State private var height: CGFloat = 50
    @State private var detectedURLs: [URL] = []
    @State private var urlDetectionTask: Task<Void, Never>? = nil
    
    private var text: Binding<String> {
        Binding(
            get: { state.pendingInstruction },
            set: { state.pendingInstruction = $0 }
        )
    }
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: text)
                .textEditorStyle(PlainTextEditorStyle())
                .styleText()
                .frame(height: height)
                .onChange(of: text.wrappedValue) {
                    if detectLinks { handleUrlDetection() }
                }
                .onKeyPress { press in
                   if press.key == .return && press.modifiers.contains(.shift) {
                       text.wrappedValue.append("\n")
                       return .handled
                   } else if press.key == .return {
                        state.sendAction()
                        return .handled
                    } else {
                        return .ignored
                    }
                }
            
            if text.wrappedValue.isEmpty { placeholderText }
            
            heightSetter
        }
        .onPreferenceChange(HeightListenerKey.self) { newHeight in
            Task { @MainActor in height = newHeight }
        }
        .opacity(state.websiteUrlsScrapeQueue.isEmpty ? 1 : 0.5)
    }
}

// MARK: - Child Components

extension PromptInput {
    private var placeholderText: some View {
        Text("New instructions...")
            .styleText(color: .gray200)
            .preventInteraction()
    }
    
    private var heightSetter: some View {
        Text(text.wrappedValue)
            .styleText()
            .preventInteraction()
            .lineLimit(maxLines)
            .hidden()
            .accessibility(hidden: true)
            .background(
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: HeightListenerKey.self,
                        value: geometry.size.height
                    )
                }
            )
    }
}

// MARK: - Used for dynamically expanding TextEditor height.

struct HeightListenerKey: PreferenceKey {
    static var defaultValue: CGFloat { 0 }
    
    static func reduce(
        value: inout CGFloat,
        nextValue: () -> CGFloat
    ) {
        value = nextValue()
    }
}


// MARK: - Private Functions

extension PromptInput {
    // Used for debounced URL detection in user input (for detecting web context).
    @MainActor
    private func handleUrlDetection() -> Void {
        // Cancel previous URL detection task to reset (if it isn't `nil`).
        urlDetectionTask?.cancel()
        
        // Create new debounced detection task (200ms).
        urlDetectionTask = Task {
            do {
                try await Task.sleep(for: .seconds(0.2))
                
                // Prevents errors due to trying to cancel a Task that's already been cancelled.
                guard !Task.isCancelled else { return }
                
                let urls = detectURLs(in: text.wrappedValue)
                
                detectedURLs = urls

                var textWithoutWebsiteUrls = text.wrappedValue
                
                for url in urls {
                    let pendingContextList = state.getPendingContextList()
                    
                    let urlExists = pendingContextList.contains { context in
                        if case .web(let existingWebsiteUrl, _, _) = context {
                            return existingWebsiteUrl == url
                        }
                        return false
                    }
                    
                    if !urlExists {
                        state.addContext(urls: [url])
                        
                        textWithoutWebsiteUrls = removeWebsiteUrlFromText(
                            text: textWithoutWebsiteUrls,
                            websiteUrl: url
                        )
                    }
                }
                
                if text.wrappedValue != textWithoutWebsiteUrls {
                    text.wrappedValue = textWithoutWebsiteUrls
                }
            } catch {
                // This catches errors thrown by the async Task.sleep method.
                // This is most likely an okay error, as it's tied to the guarded task cancellation.
                // Uncomment the debug prints below if you want to see more details.
                
                // #if DEBUG
                //    print("\n\n\n")
                //    print("Error: \(error)")
                //    print("\n\n\n")
                //#endif
            }
        }
    }
}
