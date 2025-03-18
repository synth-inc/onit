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
import Combine

struct TextInputView: View {
    @Environment(\.model) var model

    @FocusState var focused: Bool

    @Query(sort: \Chat.timestamp, order: .reverse) private var chats: [Chat]

    @Default(.mode) var mode
    
    @State private var textHeight: CGFloat = 20
    private let maxHeightLimit: CGFloat = 100

    @StateObject private var audioRecorder = AudioRecorder()
    @State private var showingAPIKeyAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @Default(.openAIToken) var openAIToken
    @Default(.useOpenAI) var useOpenAI
    @Default(.isOpenAITokenValidated) var isOpenAITokenValidated

    @State private var eventMonitor: Any? = nil

    @State private var showingMicrophonePermissionAlert = false

    @State private var addedRecordingSpaces = false
    private let recordingSpacesCount = 8

    var body: some View {
        HStack(alignment: .bottom) {
            textField
            microphoneButton
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
        .alert("Microphone Access Required", isPresented: $showingMicrophonePermissionAlert) {
            Button("Open System Settings") {
                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")!)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Onit needs access to your microphone for voice input. Please enable it in System Settings.")
        }
    }
    
    var microphoneButton: some View {
        Button(action: handleMicrophonePress) {
            if audioRecorder.isRecording {
                Image("recording")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(Color.red)
                    .frame(width: 20, height: 20)
            } else {
                Image("voice")
                    .resizable()
                    .renderingMode(.template)
                    .foregroundStyle(audioRecorder.permissionGranted ? Color.gray200 : Color.gray700)
                    .frame(width: 20, height: 20)
            }
        }
        .buttonStyle(.plain)
        .disabled(audioRecorder.isTranscribing || !isOpenAITokenValidated)
        .help(microphoneButtonHelpText)
    }
    
    private var microphoneButtonHelpText: String {
        if !isOpenAITokenValidated {
            return "Add an OpenAI API key in Settings → Models to use voice input"
        }
        if !audioRecorder.permissionGranted {
            return "Click to enable microphone access"
        }
        return audioRecorder.isRecording ? "Stop recording" : "Start voice recording"
    }

    func handleMicrophonePress() {
        if audioRecorder.permissionStatus == .denied || audioRecorder.permissionStatus == .restricted {
            showingMicrophonePermissionAlert = true
            return
        }
        
        if !audioRecorder.permissionGranted {
            Task {
                await audioRecorder.checkPermission()
                if audioRecorder.permissionGranted {
                    startRecording()
                } else if audioRecorder.permissionStatus == .denied {
                    showingMicrophonePermissionAlert = true
                }
            }
        } else {
            startRecording()
        }
    }

    func startRecording() {
        audioRecorder.startRecording()
        
        addSpacesAtCursor()
        
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .leftMouseUp) { _ in
            stopRecordingAndTranscribe()
            return nil
        }
    }
    
    func stopRecordingAndTranscribe() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        guard let audioURL = audioRecorder.stopRecording() else { return }
        audioRecorder.isTranscribing = true
        
        guard let openAIToken = openAIToken, !openAIToken.isEmpty else {
            showingAPIKeyAlert = true
            audioRecorder.isTranscribing = false
            return
        }
        let whisperService = WhisperService(apiKey: openAIToken)
        
        Task {
            do {
                let transcription = try await whisperService.transcribe(audioURL: audioURL)
                DispatchQueue.main.async {
                    removeSpacesAtCursor()
                    let cursorPosition = model.pendingInstructionCursorPosition
                    model.pendingInstruction.insert(contentsOf: transcription, at: model.pendingInstruction.index(model.pendingInstruction.startIndex, offsetBy: cursorPosition))
                    audioRecorder.isTranscribing = false
                }
            } catch {
                removeSpacesAtCursor()
                errorMessage = error.localizedDescription
                showingErrorAlert = true
                audioRecorder.isTranscribing = false
            }
        }
    }

     private func addSpacesAtCursor() {
         guard !addedRecordingSpaces else { return }
        
         let cursorPosition = model.pendingInstructionCursorPosition
         let spaces = String(repeating: " ", count: recordingSpacesCount)
        
         model.pendingInstruction.insert(contentsOf: spaces, at:
             model.pendingInstruction.index(model.pendingInstruction.startIndex,
                                           offsetBy: cursorPosition))
        
         addedRecordingSpaces = true
     }
     
     private func removeSpacesAtCursor() {
         print("Removing spaces at cursor positon \(model.pendingInstructionCursorPosition)")
         guard addedRecordingSpaces else { return }
        
         let cursorPosition = model.pendingInstructionCursorPosition
         let startPosition = cursorPosition
         let endPosition = max(0, startPosition + recordingSpacesCount)
         let startIndex = model.pendingInstruction.index(model.pendingInstruction.startIndex,
                                                         offsetBy: startPosition)
         let endIndex = model.pendingInstruction.index(model.pendingInstruction.startIndex,
                                                       offsetBy: endPosition)

         print("endPosition: \(endPosition), startPosition: \(startPosition)")
         print("startIndex: \(startIndex), endIndex: \(endIndex)")

         print("Before removing: \"\(model.pendingInstruction)\"")
         model.pendingInstruction.removeSubrange(startIndex..<endIndex)
         print("After removing: \"\(model.pendingInstruction)\"")

         addedRecordingSpaces = false
     }

    @ViewBuilder
    var textField: some View {
        @Bindable var model = model

        TextViewWrapper(
            text: $model.pendingInstruction,
            cursorPosition: $model.pendingInstructionCursorPosition,
            dynamicHeight: $textHeight,
            onSubmit: sendAction,
            maxHeight: maxHeightLimit,
            placeholder: placeholderText,
            audioRecorder: audioRecorder)
        .focused($focused)
        .frame(height: min(textHeight, maxHeightLimit))
        .onAppear { focused = true }
        .onChange(of: model.textFocusTrigger) { focused = true }
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
        let inputText = (model.pendingInstruction ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !inputText.isEmpty else { return }
        
        model.createAndSavePrompt()
    }

    var sendButton: some View {
        Button(action: sendAction) {
            Image(mode == .local ? .circleArrowUpDotted : .circleArrowUp)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(
                    (model.pendingInstruction.isEmpty)
                        ? Color.gray700 : (mode == .local ? .limeGreen : Color.blue400)
                )
                .frame(width: 22, height: 22, alignment: .center)
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
