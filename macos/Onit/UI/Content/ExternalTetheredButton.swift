//
//  ExternalTetheredButton.swift
//  Onit
//
//  Created by Kévin Naudin on 02/04/2025.
//


import Defaults
import SwiftUI
import Foundation

struct ExternalTetheredButton: View {
    @Environment(\.appState) var appState
    @Environment(\.windowState) var windowState
    @Environment(\.openSettings) var openSettings
    
    static let width: CGFloat = 19
    static let height: CGFloat = 53
    static let containerWidth: CGFloat = width * 2
    static let containerHeight: CGFloat = height * 2
    static let borderWidth: CGFloat = 1.5
    
    var onClick: (() -> Void)
    var onDrag: ((CGFloat) -> Void)?
    
    @State private var hovering = false
    @State private var isDragging = false
    @State private var dragStartTime: Date?
    
    private var fitActiveWindowPrompt: String {
        return "Launch Onit"
    }
    
    private var containsInput: Bool {
        return windowState?.pendingInput != nil
    }
    
    private var containsInputBinding: Binding<Bool> {
        Binding {
            containsInput
        } set: { _ in
            
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Button(action: tetherAction) {
                    Image(.dots)
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(180))
                        .frame(width: Self.width, height: Self.height, alignment: .center)
                }
                .buttonStyle(
                    ExternalTetheredButtonStyle(
                        hovering: $hovering,
                        containsInput: containsInputBinding,
                        tooltipText: fitActiveWindowPrompt
                    )
                )
                .offset(x: containsInput ? Self.borderWidth : 0)
                .simultaneousGesture(dragGesture)
            }
            
            Spacer()
        }
        .frame(width: Self.containerWidth, height: Self.containerHeight, alignment: .trailing)
        .offset(x: 1)
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStartTime == nil {
                    dragStartTime = Date()
                }
                
                if let startTime = dragStartTime,
                   Date().timeIntervalSince(startTime) > 0.1 {
                    isDragging = true
                    onDrag?(value.translation.height)
                }
            }
            .onEnded { value in
                dragStartTime = nil
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isDragging = false
                }
            }
    }
    
    private func tetherAction() {
        guard !isDragging else { return }
        
        onClick()
    }
}

#Preview {
    ExternalTetheredButton {
        
    }
}
