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
    @Environment(\.windowState) private var state

    @FocusState var focused: Bool

    @Query(sort: \Chat.timestamp, order: .reverse) private var allChats: [Chat]
    
    private var chats: [Chat] {
        return allChats.filter {
            $0.windowHash == state.trackedWindow?.hash
        }
    }

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

    @State private var transcriptionTask: Task<Void, Never>? = nil

    var body: some View {
        HStack(alignment: .center) {
            textField
            
            HStack(alignment: .center, spacing: 0) {
                WebSearchButton()
                microphoneButton
                sendButton
            }
        }
        .padding(.top, 4)
        .padding(.bottom, 12)
        .padding(.horizontal, 16)
        .background {
            upListener
            downListener
            newListener
        }
        .opacity(state.websiteUrlsScrapeQueue.isEmpty ? 1 : 0.5)
        .onDisappear {
            if audioRecorder.isRecording {
                cancelRecording()
            }
            transcriptionTask?.cancel()
            transcriptionTask = nil
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
        .alert("Recording Error", isPresented: Binding<Bool>(
            get: { audioRecorder.recordingError != nil },
            set: { if !$0 { audioRecorder.clearError() } }
        )) {
            Button("OK", role: .cancel) {
                audioRecorder.clearError()
            }
        } message: {
            Text(audioRecorder.recordingError?.localizedDescription ?? "An unknown error occurred")
        }
    }

    var microphoneButton: some View {
        IconButton(
            icon: audioRecorder.isRecording ? .recording : .voice,
            action: { handleMicrophonePress() },
            isActive: audioRecorder.isRecording,
            activeColor: audioRecorder.isRecording ? Color.red : nil,
            inactiveColor: !audioRecorder.permissionGranted ? Color.gray700 : nil
        )
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
        guard audioRecorder.startRecording() else {
            // Recording failed to start
            return
        }
        
        addSpacesAtCursor()
        
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
        
        transcriptionTask = Task {
            do {
                let transcription = try await whisperService.transcribe(audioURL: audioURL)
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        removeSpacesAtCursor()
                        
                        let cursorPosition = state.pendingInstructionCursorPosition
                        state.pendingInstruction.insert(
                            contentsOf: transcription,
                            at: state.pendingInstruction.index(state.pendingInstruction.startIndex, offsetBy: cursorPosition)
                        )
                        
                        audioRecorder.isTranscribing = false
                    }
                }
            } catch {
                if !Task.isCancelled {
                    DispatchQueue.main.async {
                        removeSpacesAtCursor()
                        errorMessage = error.localizedDescription
                        showingErrorAlert = true
                        audioRecorder.isTranscribing = false
                    }
                }
            }
        }
    }

     private func addSpacesAtCursor() {
         guard !addedRecordingSpaces else { return }
         
         let cursorPosition = state.pendingInstructionCursorPosition
         let spaces = String(repeating: " ", count: recordingSpacesCount)
        
         state.pendingInstruction.insert(
            contentsOf: spaces,
            at: state.pendingInstruction.index(
                state.pendingInstruction.startIndex,
                offsetBy: cursorPosition
            )
         )
        
         addedRecordingSpaces = true
     }
     
     private func removeSpacesAtCursor() {
         guard addedRecordingSpaces else { return }
        
         let cursorPosition = state.pendingInstructionCursorPosition
         let startPosition = cursorPosition
         let endPosition = max(0, startPosition + recordingSpacesCount)
         let startIndex = state.pendingInstruction.index(state.pendingInstruction.startIndex,
                                                         offsetBy: startPosition)
         let endIndex = state.pendingInstruction.index(state.pendingInstruction.startIndex,
                                                       offsetBy: endPosition)
         
         state.pendingInstruction.removeSubrange(startIndex..<endIndex)
         
         addedRecordingSpaces = false
     }

    @ViewBuilder
    var textField: some View {
        @Bindable var state = state
        
        TextViewWrapper(
            text: $state.pendingInstruction,
            cursorPosition: $state.pendingInstructionCursorPosition,
            dynamicHeight: $textHeight,
            onSubmit: sendAction,
            maxHeight: maxHeightLimit,
            placeholder: placeholderText,
            audioRecorder: audioRecorder,
            detectLinks: true
        )
        .focused($focused)
        .frame(height: min(textHeight, maxHeightLimit))
        .onAppear { focused = true }
        .onChange(of: state.textFocusTrigger) { focused = true }
        .appFont(.medium16)
        .foregroundStyle(.white)
    }

    var placeholderText: String {
        if let currentChat = state.currentChat {
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
        if state.websiteUrlsScrapeQueue.isEmpty {
            let inputText = state.pendingInstruction.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !inputText.isEmpty else { return }   
            state.createAndSavePrompt()
        }
    }

    var sendButton: some View {
        IconButton(
            icon: mode == .local ? .circleArrowUpDotted : .circleArrowUp,
            iconSize: 22,
            action: { sendAction() },
            inactiveColor:
                state.pendingInstruction.isEmpty ? .gray700 :
                mode == .local ? .limeGreen :
                Color.blue400
        )
        .disabled(state.pendingInstruction.isEmpty)
        .keyboardShortcut(.return, modifiers: [])
    }

    var upListener: some View {
        Button {
            guard !chats.isEmpty else { return }
            
            if state.historyIndex + 1 < chats.count {
                state.historyIndex += 1
                state.currentChat = chats[state.historyIndex]
                state.currentPrompts = chats[state.historyIndex].prompts
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.upArrow, modifiers: [])
    }

    var downListener: some View {
        Button {
            if state.historyIndex > 0 {
                state.historyIndex -= 1
                state.currentChat = chats[state.historyIndex]
                state.currentPrompts = chats[state.historyIndex].prompts
            } else if state.historyIndex == 0 {
                state.historyIndex = -1
                state.currentChat = nil
                state.currentPrompts = nil
                focused = true
            }
        } label: {
            EmptyView()
        }
        .keyboardShortcut(.downArrow, modifiers: [])
    }

    var newListener: some View {
        Button {
            state.newChat()
        } label: {
            EmptyView()
        }
        .keyboardShortcut("n")
    }

    func cancelRecording() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        _ = audioRecorder.stopRecording()
        audioRecorder.isTranscribing = false
        
        if addedRecordingSpaces {
            removeSpacesAtCursor()
        }
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
