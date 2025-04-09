//
//  HistoryDeleteToast.swift
//  Onit
//
//  Created by Loyd Kim on 4/4/25.
//

import SwiftUI
import SwiftData

struct HistoryDeleteToast: View {
    @Environment(\.model) var model
    
    var text: String
    let chat: Chat?
    
    @State private var isHoveringUndo: Bool = false
    @State private var isHoveringDismiss: Bool = false
    @State private var deletionTimer: Timer? = nil
    //
    @State private var fadeOutTimer: Timer? = nil
    @State private var fadeOutOpacity: CGFloat = 1
    @State private var topOffset: CGFloat = -8
    @State private var fadeOutUndo: Bool = false
    
    let hoverOpacity: Double = 0.5
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(text)
                undoButton
                dismissButton
            }
            .frame(alignment: .center)
            .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(.gray700)
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.4), radius: 11, x: 0, y: 3)
        .onChange(of: model.chatDeletionTimePassed) {
            if model.chatDeletionTimePassed >= 5 {
                fadeOutOpacity = 1
                createFadeOutTimer()
                removeDeletionTimer()
            }
        }
        .onChange(of: fadeOutOpacity) {
            if fadeOutOpacity <= 0 {
                removeFadeOutTimer()
                
                if fadeOutUndo { model.chatQueuedForDeletion = nil }
                else if let chat = chat { model.deleteChat(chat: chat) }
                else { model.chatDeletionFailed = false }
            }
        }
        .onAppear {
            model.chatDeletionTimePassed = 0
            fadeOutOpacity = 1
            createDeletionTimer()
            withAnimation(.easeOut(duration: animationDuration)) { topOffset = 0 }
        }
        .onDisappear {
            removeDeletionTimer()
            model.chatDeletionTimePassed = 0
        }
        .opacity(model.historyDeleteToastDismissed ? 0 : fadeOutOpacity)
        .offset(y: topOffset)
        .animation(.easeInOut(duration: animationDuration), value: topOffset)
        .animation(.easeInOut(duration: animationDuration), value: model.historyDeleteToastDismissed)
        .allowsHitTesting(!model.historyDeleteToastDismissed)
    }
}

/// Child Components
extension HistoryDeleteToast {
    @ViewBuilder
    var undoButton: some View {
        if !model.chatDeletionFailed {
            Button {
                fadeOutUndo = true
                createFadeOutTimer()
            } label: {
                Text("Undo").underline().font(.system(size: 14))
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.leading, 12)
            .padding(.trailing, 4)
            .onHover{ hovering in isHoveringUndo = hovering }
            .opacity(isHoveringUndo ? hoverOpacity : 1)
            .animation(.easeIn(duration: animationDuration), value: isHoveringUndo)
        }
    }
    
    var dismissButton: some View {
        Button {
            withAnimation(.easeIn(duration: animationDuration)) {
                model.historyDeleteToastDismissed = true
            }
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


/// Helper Functions
extension HistoryDeleteToast {
    func createDeletionTimer() {
        deletionTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            Task { @MainActor in model.chatDeletionTimePassed += 1 }
        }
        if let deletionTimer = deletionTimer {
            RunLoop.current.add(deletionTimer, forMode: .common)
        }
    }
    
    func removeDeletionTimer() {
        deletionTimer?.invalidate()
        deletionTimer = nil
    }
    
    func createFadeOutTimer() {
        fadeOutTimer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { _ in
            Task { @MainActor in fadeOutOpacity -= 0.1 }
        }
        if let fadeOutTimer = fadeOutTimer {
            RunLoop.current.add(fadeOutTimer, forMode: .common)
        }
    }
    
    func removeFadeOutTimer() {
        fadeOutTimer?.invalidate()
        fadeOutTimer = nil
    }
}
