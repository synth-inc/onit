//
//  MicrophoneButton.swift
//  Onit
//
//  Created by Loyd Kim on 4/17/25.
//

import Defaults
import SwiftUI

struct MicrophoneButton: View {
    @Environment(\.windowState) private var windowState
    
    @Default(.openAIToken) var openAIToken
    
    @ObservedObject private var audioRecorder: AudioRecorder
    
    init(audioRecorder: AudioRecorder) {
        self.audioRecorder = audioRecorder
    }
    
    @State private var transcriptionTask: Task<Void, Never>? = nil
    @State private var showingMicrophonePermissionAlert = false
    @State private var addedRecordingSpaces = false
    @State private var eventMonitor: Any? = nil
    @State private var showingAPIKeyAlert = false
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    
    private let recordingSpacesCount = 8
    
    var body: some View {
        PromptCoreFooterButton(
            text: audioRecorder.isRecording ? "􀊰 Stop" : "􀊰 Voice",
            action: { handleMicrophonePress() },
            background: audioRecorder.isRecording ? Color.red.opacity(0.15) : .clear,
            hoverBackground: audioRecorder.isRecording ? Color.red.opacity(0.3) : .gray600,
            fontColor: audioRecorder.isRecording ? .red : .gray200
        )
        .disabled(audioRecorder.isTranscribing)
        .help(microphoneButtonHelpText)
        .onDisappear {
            if audioRecorder.isRecording { cancelRecording() }
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
}

// MARK: - Private Variables

extension MicrophoneButton {
    private var microphoneButtonHelpText: String {
        if !audioRecorder.permissionGranted {
            return "Click to enable microphone access"
        } else if audioRecorder.isRecording {
            return "Stop recording"
        } else {
            return "Start voice recording"
        }
    }
}

// MARK: - Private Functions

extension MicrophoneButton {
    private func handleMicrophonePress() {
        if audioRecorder.permissionStatus == .denied || audioRecorder.permissionStatus == .restricted {
            AnalyticsManager.Chat.voicePressed(isAvailable: false)
            showingMicrophonePermissionAlert = true
            return
        }
        
        if !audioRecorder.permissionGranted {
            Task {
                await audioRecorder.checkPermission()
                
                if audioRecorder.permissionGranted {
                    AnalyticsManager.Chat.voicePressed(isAvailable: true)
                    startRecording()
                } else if audioRecorder.permissionStatus == .denied {
                    AnalyticsManager.Chat.voicePressed(isAvailable: false)
                    showingMicrophonePermissionAlert = true
                }
            }
        } else {
            AnalyticsManager.Chat.voicePressed(isAvailable: true)
            startRecording()
        }
    }
    
    private func startRecording() {
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
    
    @MainActor
    private func handleTranscriptionSuccess(_ transcription: String) {
        removeSpacesAtCursor()
        
        let cursorPosition = windowState.pendingInstructionCursorPosition
        
        windowState.pendingInstruction.insert(
            contentsOf: transcription,
            at: windowState.pendingInstruction.index(
                windowState.pendingInstruction.startIndex,
                offsetBy: cursorPosition
            )
        )
        
        audioRecorder.isTranscribing = false
    }
    
    @MainActor
    private func handleTranscriptionFailure(_ error: String) {
        removeSpacesAtCursor()
        errorMessage = error
        showingErrorAlert = true
        audioRecorder.isTranscribing = false
    }
    
    private func handleAudioOnClient(_ clientOpenAIToken: String, _ audioURL: URL) {
        let whisperService = WhisperService(apiKey: clientOpenAIToken)
        
        transcriptionTask = Task {
            do {
                let transcription = try await whisperService.transcribe(audioURL: audioURL)
                
                if !Task.isCancelled {
                    handleTranscriptionSuccess(transcription)
                }
            } catch {
                if !Task.isCancelled {
                    handleTranscriptionFailure(error.localizedDescription)
                }
            }
        }
    }
    
    private func handleAudioOnServer(_ audioURL: URL) {
        let serverTranscriptionService = TranscriptionService()
        
        transcriptionTask = Task {
            do {
                let transcription = try await serverTranscriptionService.transcribe(audioURL: audioURL)
                
                if !Task.isCancelled {
                    handleTranscriptionSuccess(transcription)
                }
            } catch {
                if !Task.isCancelled {
                    handleTranscriptionFailure(error.localizedDescription)
                }
            }
        }
    }
    
    private func stopRecordingAndTranscribe() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        
        guard let audioURL = audioRecorder.stopRecording() else { return }
        
        // Preventing transcription of silent recordings.
        guard audioRecorder.recordingIsNotSilent() else {
            removeSpacesAtCursor()
            return
        }
        
        audioRecorder.isTranscribing = true
        
        guard let clientOpenAIToken = openAIToken, !clientOpenAIToken.isEmpty else {
            handleAudioOnServer(audioURL)
            return
        }
        
        handleAudioOnClient(clientOpenAIToken, audioURL)
    }
    
    private func cancelRecording() {
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
    
    private func addSpacesAtCursor() {
        guard !addedRecordingSpaces else { return }
        
        let cursorPosition = windowState.pendingInstructionCursorPosition
        let spaces = String(repeating: " ", count: recordingSpacesCount)
        
        // We've seen index out of bounds errors here, so we need to clamp the index
        let targetIndex = windowState.pendingInstruction.index(
            windowState.pendingInstruction.startIndex,
            offsetBy: min(max(0, cursorPosition), windowState.pendingInstruction.count)
        )
        windowState.pendingInstruction.insert(contentsOf: spaces, at: targetIndex)
        addedRecordingSpaces = true
    }
    
    private func removeSpacesAtCursor() {
        guard addedRecordingSpaces else { return }
        
        let cursorPosition = windowState.pendingInstructionCursorPosition
        let startPosition = cursorPosition
        let endPosition = max(0, startPosition + recordingSpacesCount)
        
        let startIndex = windowState.pendingInstruction.index(
            windowState.pendingInstruction.startIndex,
            offsetBy: startPosition
        )
        
        let endIndex = windowState.pendingInstruction.index(
            windowState.pendingInstruction.startIndex,
            offsetBy: endPosition
        )
        
        windowState.pendingInstruction.removeSubrange(startIndex..<endIndex)
        
        addedRecordingSpaces = false
    }
}
