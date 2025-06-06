//
//  CaretPositionDebug.swift
//  Onit
//
//  Created by Kévin Naudin on 06/06/2025.
//

import SwiftUI
import ApplicationServices

// TODO: KNA - Should be removed after debugging
@MainActor
class CaretPositionDebugModel: ObservableObject, CaretPositionDelegate {
    @Published var lastCaretInfo: String = "No caret detected"
    @Published var caretHistory: [CaretEvent] = []
    @Published var debugOutput: String = ""
    @Published var debugCountdown: Int = 0
    @Published var isDebugCountdownActive: Bool = false
    
    private let caretManager = CaretPositionManager.shared
    private var isListening = false
    private var eventCounter = 0
    private var countdownTimer: Timer?
    
    struct CaretEvent: Identifiable {
        let id = UUID()
        let timestamp: String
        let message: String
        let position: CGRect?
        let application: String?
    }
    
    func startListening() {
        if !isListening {
            caretManager.addDelegate(self)
            isListening = true
        }
    }
    
    func stopListening() {
        if isListening {
            caretManager.removeDelegate(self)
            isListening = false
            countdownTimer?.invalidate()
        }
    }
    
    func clearHistory() {
        caretHistory.removeAll()
        eventCounter = 0
        debugOutput = ""
    }
    
    func triggerDebugWithDelay() {
        debugCountdown = 3
        isDebugCountdownActive = true
        
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            Task { @MainActor in
                if self.debugCountdown > 1 {
                    self.debugCountdown -= 1
                } else {
                    self.countdownTimer?.invalidate()
                    self.countdownTimer = nil
                    self.isDebugCountdownActive = false
                    self.executeDebug()
                }
            }
        }
    }
    
    func cancelDebugCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        isDebugCountdownActive = false
        debugCountdown = 0
    }
    
    private func executeDebug() {
        debugOutput = caretManager.debugCaretDetection()
    }
    
    func triggerImmediateDebug() {
        executeDebug()
    }
    
    private func addEvent(message: String, position: CGRect? = nil, application: String? = nil) {
        eventCounter += 1
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        let timestamp = formatter.string(from: Date())
        
        let event = CaretEvent(
            timestamp: timestamp,
            message: message,
            position: position,
            application: application
        )
        
        lastCaretInfo = "\(timestamp) - \(message)"
        caretHistory.insert(event, at: 0)
        
        if caretHistory.count > 10 {
            caretHistory.removeLast()
        }
    }
    
    // MARK: - CaretPositionDelegate
    
    func caretPositionDidChange(_ position: CGRect, in application: String, element: AXUIElement) {
        let message = "Caret moved in \(application) to (\(Int(position.origin.x)), \(Int(position.origin.y)))"
        addEvent(message: message, position: position, application: application)
    }
    
    func caretPositionDidUpdate(_ position: CGRect, in application: String, element: AXUIElement) {
        
    }
    
    func caretDidDisappear() {
        addEvent(message: "Caret disappeared")
    }
}

struct CaretPositionDebug: View {
    @StateObject private var caretManager = CaretPositionManager.shared
    @StateObject private var model = CaretPositionDebugModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Caret Position Detection")
                    .font(.title)
                    .fontWeight(.bold)
                
                VStack(alignment: .leading, spacing: 10) {
                    Text("Caret Status:")
                        .font(.headline)
                    
                    Text(caretManager.isCaretVisible ? "✅ Caret visible" : "❌ Caret not detected")
                        .foregroundColor(caretManager.isCaretVisible ? .green : .red)
                    
                    if let position = caretManager.currentCaretPosition {
                        Text("Position: x=\(Int(position.origin.x)), y=\(Int(position.origin.y))")
                        Text("Size: \(Int(position.width)) x \(Int(position.height))")
                    }
                    
                    if let app = caretManager.currentApplication {
                        Text("Application: \(app)")
                    }
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Debug Controls:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        HStack {
                            if model.isDebugCountdownActive {
                                VStack {
                                    Text("Debug in \(model.debugCountdown)s...")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    HStack {
                                        Button("Cancel") {
                                            model.cancelDebugCountdown()
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                        
                                        Button("Debug Now") {
                                            model.cancelDebugCountdown()
                                            model.triggerImmediateDebug()
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .controlSize(.small)
                                    }
                                }
                            } else {
                                Button("Debug Detection (3s delay)") {
                                    model.triggerDebugWithDelay()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            
                            Button("Clear History") {
                                model.clearHistory()
                            }
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                HStack(alignment: .top, spacing: 20) {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Last Information:")
                                .font(.headline)
                            
                            Text(model.lastCaretInfo)
                                .padding()
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(8)
                        }
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("History (10 recent events):")
                                .font(.headline)
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 5) {
                                    ForEach(model.caretHistory.prefix(10)) { event in
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(event.timestamp) - \(event.message)")
                                                .font(.caption)
                                            if let position = event.position {
                                                Text("   → Size: \(Int(position.width))x\(Int(position.height))")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        .padding(.horizontal)
                                    }
                                }
                            }
                            .frame(height: 300)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Debug Output:")
                            .font(.headline)
                        
                        if !model.debugOutput.isEmpty {
                            ScrollView {
                                Text(model.debugOutput)
                                    .font(.caption)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .textSelection(.enabled)
                                    .padding()
                            }
                            .frame(height: 400)
                            .background(Color.black.opacity(0.8))
                            .foregroundColor(.green)
                            .cornerRadius(8)
                        } else {
                            Text("No debug output yet. Use 'Debug Detection' to generate output.")
                                .font(.caption)
                                .padding()
                                .frame(height: 400)
                                .frame(maxWidth: .infinity)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .onAppear {
            model.startListening()
        }
        .onDisappear {
            model.stopListening()
        }
    }
}

#Preview {
    CaretPositionDebug()
} 
