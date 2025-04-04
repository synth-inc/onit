//
//  HistoryDeleteNotification.swift
//  Onit
//
//  Created by Loyd Kim on 4/4/25.
//

import SwiftUI
import SwiftData

struct HistoryDeleteNotification: View {
    @Environment(\.model) var model
    
    let chatName: String
    let chatId: PersistentIdentifier
    let startTime: Date
    let dismiss: () -> Void
    
    @State private var isHoveringUndo: Bool = false
    @State private var isHoveringDismiss: Bool = false
    @State private var progressPercentage: Double = 0
    @State private var timer: Timer? = nil
    
    let hoverOpacity: Double = 0.5
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                name
                undoButton
                dismissButton
            }
            .frame(alignment: .center)
            .foregroundColor(.white)
            
            ProgressBar(manual: ProgressBar.Manual(
                progressPercentage: progressPercentage
            ))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.gray700)
        .overlay(
            RoundedRectangle(cornerRadius: 8).stroke(.gray200, lineWidth: 1)
        )
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.4), radius: 11, x: 0, y: 3)
        .onAppear {
            // 1/60 = 0.016s = 60fps
            timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { _ in
                Task { @MainActor in updateProgress() }
            }
            
            if let timer = timer {
                RunLoop.current.add(timer, forMode: .common)
            }
        }
        .onDisappear {
            // Cleaning up the timer when component unmounts.
            timer?.invalidate()
            timer = nil
        }
    }
}

/// Child Components
extension HistoryDeleteNotification {
    var name: some View {
        Text("Deleted: \(chatName)")
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.system(size: 14))
            .lineLimit(1)
            .truncationMode(.tail)
    }
    
    var undoButton: some View {
        Button {
            undoDelete()
        } label: {
            Text("Undo").underline().font(.system(size: 14))
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.leading, 12)
        .padding(.trailing, 8)
        .onHover{ hovering in isHoveringUndo = hovering }
        .opacity(isHoveringUndo ? hoverOpacity : 1)
        .animation(.easeIn(duration: animationDuration), value: isHoveringUndo)
    }
    
    var dismissButton: some View {
        Button {
            // Cleaning up the timer.
            timer?.invalidate()
            timer = nil
            
            dismiss()
        } label: {
            Image(.smallCross)
                .renderingMode(.template)
                .foregroundStyle(.white)
                .frame(width: 8, height: 8)
        }
        .buttonStyle(PlainButtonStyle())
        .onHover{ hovering in isHoveringDismiss = hovering }
        .opacity(isHoveringDismiss ? hoverOpacity : 1)
        .animation(.easeIn(duration: animationDuration), value: isHoveringDismiss)
    }
}

/// Private Functions
extension HistoryDeleteNotification {
    private func undoDelete() {
        model.removeChatFromDeleteQueue(chatId: chatId)
    }
    
    private func updateProgress() {
        let elapsedTime = Date().timeIntervalSince(startTime)
        let totalDurationSeconds = model.deleteChatDurationSeconds
        let updatedProgressPercentage = max(1 - (elapsedTime / totalDurationSeconds), 0.0)
        
        // Adding animation here, rather than directly on the ManualProgressBar component,
        // because the ManualProgressBar progression animation differs based on used case.
        withAnimation(.linear(duration: 0.1)) {
            progressPercentage = updatedProgressPercentage
        }
        
        if progressPercentage <= 0 {
            timer?.invalidate()
            timer = nil
        }
    }
}
