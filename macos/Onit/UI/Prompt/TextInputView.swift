//
//  PreferencesView.swift
//  Onit
//
//  Created by Benjamin Sage on 9/17/24.
//

import Defaults
import KeyboardShortcuts
import SwiftData
import SwiftUI

struct TextInputView: View {
    @Environment(\.model) var model

    @FocusState var focused: Bool

    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]

    @Default(.mode) var mode
    
    @State private var textHeight: CGFloat = 20
    private let maxHeightLimit: CGFloat = 100

    @StateObject private var audioRecorder = AudioRecorder()
    @State private var isTranscribing = false
    @State private var showingAPIKeyAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        HStack(alignment: .bottom) {
            textField
            if audioRecorder.isRecording {
                Image(systemName: "mic.circle.fill")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.red)
                    .frame(width: 18, height: 18)
                    .help("Recording... Release to stop")
            } else if isTranscribing {
                ProgressView()
                    .scaleEffect(0.5)
                    .frame(width: 18, height: 18)
                    .help("Transcribing audio...")
            } else {
                microphoneButton
            }
            sendButton
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        .padding(.horizontal, 16)
        .background {
            upListener
            downListener
            newListener
        }
        .alert("OpenAI API Key Required", isPresented: $showingAPIKeyAlert) {
            Button("Open Settings") {
                NSWorkspace.shared.open(URL(string: "onit://settings/general")!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please set your OpenAI API key in Settings to use voice transcription.")
        }
        .alert("Transcription Error", isPresented: $showingErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    var microphoneButton: some View {
        Button(action: startRecording) {
            Image(systemName: "mic.circle.fill")
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(audioRecorder.permissionGranted ? Color.blue400 : Color.gray700)
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .disabled(!audioRecorder.permissionGranted || isTranscribing)
        .help(audioRecorder.permissionGranted ? "Record voice instruction" : "Microphone access not granted")
    }
    
    func startRecording() {
        audioRecorder.startRecording()
        
        // Add a long press gesture recognizer
        NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { _ in
            stopRecordingAndTranscribe()
            return nil
        }
    }
    
    func stopRecordingAndTranscribe() {
        guard let audioURL = audioRecorder.stopRecording() else { return }
        
        isTranscribing = true
        
        // Get API key from settings
        @AppStorage("openai_api_key") var openaiApiKey: String = ""
        guard !openaiApiKey.isEmpty else {
            showingAPIKeyAlert = true
            isTranscribing = false
            return
        }
        let whisperService = WhisperService(apiKey: openaiApiKey)
        
        Task {
            do {
                let transcription = try await whisperService.transcribe(audioURL: audioURL)
                DispatchQueue.main.async {
                    model.pendingInstruction = transcription
                    isTranscribing = false
                }
            } catch {
                errorMessage = error.localizedDescription
                showingErrorAlert = true
                isTranscribing = false
            }
        }
    }

    @ViewBuilder
    var textField: some View {
        @Bindable var model = model

        ZStack(alignment: .leading) {
            TextViewWrapper(
                text: $model.pendingInstruction,
                dynamicHeight: $textHeight,
                onSubmit: sendAction,
                maxHeight: maxHeightLimit,
                placeholder: placeholderText)
            .focused($focused)
            .frame(height: min(textHeight, maxHeightLimit))
            .onAppear { focused = true }
            .onChange(of: model.textFocusTrigger) { focused = true }
        }
        .appFont(.medium16)
        .foregroundStyle(.white)
    }

    var placeholderText: String {
        if let currentChat = model.currentChat {
            if !currentChat.isEmpty {

                if let keyboardShortcutString = KeyboardShortcuts.getShortcut(for: .newChat)?
                    .description
                {
                    "Follow-up... (" + keyboardShortcutString + " for new)"
                } else {
                    "Follow-up..."
                }

            } else {
                "New instructions..."
            }
        } else {
            "New instructions..."
        }
    }

    func sendAction() {
        let inputText = model.pendingInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Add empty check
        guard !inputText.isEmpty else { return }
        
        model.createAndSavePrompt()
    }

    var sendButton: some View {
        Button(action: sendAction) {
            Image(mode == .local ? .circleArrowUpDotted : .circleArrowUp)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(
                    model.pendingInstruction.isEmpty
                        ? Color.gray700 : (mode == .local ? .limeGreen : Color.blue400)
                )
                .frame(width: 18, height: 18)
        }
        .buttonStyle(.plain)
        .disabled(model.pendingInstruction.isEmpty)
        .keyboardShortcut(.return, modifiers: [])
    }

    var upListener: some View {
        Button {
            guard !chats.isEmpty else { return }

            if model.historyIndex + 1 < chats.count {
                model.historyIndex += 1
                model.currentChat = chats[model.historyIndex]
                model.currentPrompts = chats[model.historyIndex].prompts
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.upArrow, modifiers: [])
    }

    var downListener: some View {
        Button {
            if model.historyIndex > 0 {
                model.historyIndex -= 1
                model.currentChat = chats[model.historyIndex]
                model.currentPrompts = chats[model.historyIndex].prompts
            } else if model.historyIndex == 0 {
                model.historyIndex = -1
                model.currentChat = nil
                model.currentPrompts = nil
                focused = true
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.downArrow, modifiers: [])
    }

    var newListener: some View {
        Button {
            model.newChat()
        } label: {
            EmptyView()
        }
        .keyboardShortcut("n")
    }
}

#Preview {
    TextInputView()
}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            insertionPointColor = .white
        }
    }
}
