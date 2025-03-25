//
//  ExternalTetheredButton.swift
//  Onit
//
//  Created by Kévin Naudin on 02/04/2025.
//


import Defaults
import SwiftUI

struct ExternalTetheredButton: View {
    @Environment(\.appState) var appState
    @Environment(\.windowState) var windowState
    @Environment(\.openSettings) var openSettings
    
    @ObservedObject private var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    static let width: CGFloat = 16
    static let height: CGFloat = 42
    static let borderWidth: CGFloat = 1
    
    var onDrag: ((CGFloat) -> Void)?
    
    @State private var hovering = false
    @State private var isDragging = false
    @State private var dragStartTime: Date?
    @State private var gradientRotation: Double = 0
    
    private var isAccessibilityFlagsEnabled: Bool {
        featureFlagsManager.accessibility && featureFlagsManager.accessibilityAutoContext
    }
    
    private var isAccessibilityAuthorized: Bool {
        accessibilityPermissionManager.accessibilityPermissionStatus == .granted
    }
    
    private var fitActiveWindowPrompt: String {
        guard featureFlagsManager.accessibility else {
            return "⚠ Enable Auto-Context in Settings"
        }
        guard featureFlagsManager.accessibilityAutoContext else {
            return "⚠ Enable Current Window in Settings"
        }
        guard isAccessibilityAuthorized else {
            return "⚠ Allow Onit application in \"Privacy & Security/Accessibility\""
        }
        
        return "Fit to active window"
    }
    
    private var containsInput: Bool {
        return windowState.pendingInput != nil
    }
    
    private var buttonWidth: CGFloat {
        var width = Self.width
        
        if hovering {
            width *= 1.3
        }
        
        if containsInput {
            width += Self.borderWidth * 2
        }
        
        return width
    }
    private var buttonHeight: CGFloat {
        var height = Self.height
        
        if hovering {
            height *= 1.3
        }
        
        if containsInput {
            height += Self.borderWidth * 2
        }
        
        return height
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            HStack {
                Button(action: tetherAction) {
                    Image(.smallChevRight)
                        .renderingMode(.template)
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(180))
                        .frame(width: Self.width, height: Self.height, alignment: .leading)
                        .overlay(
                            Group {
                                if !isAccessibilityFlagsEnabled || !isAccessibilityAuthorized {
                                    Rectangle()
                                        .fill(.black)
                                        .frame(height: 2)
                                        .rotationEffect(.degrees(45))
                                        .offset(y: 0)
                                    
                                    Rectangle()
                                        .fill(.gray200)
                                        .frame(height: 1)
                                        .rotationEffect(.degrees(45))
                                        .offset(y: 0)
                                }
                            }
                        )
                }
                //.frame(width: buttonWidth, height: buttonHeight)
                .buttonStyle(
                    ExternalTetheredButtonStyle(
                        gradientRotation: $gradientRotation,
                        hovering: $hovering,
                        tooltipText: fitActiveWindowPrompt,
                        containsInput: containsInput
                    )
                )
                .simultaneousGesture(dragGesture)
            }
            
            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 5).repeatForever(autoreverses: false)) {
                gradientRotation = 360
            }
        }
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
        
        guard isAccessibilityFlagsEnabled else {
            appState.setSettingsTab(tab: .accessibility)
            openSettings()
            return
        }
        guard isAccessibilityAuthorized else {
            AccessibilityPermissionManager.shared.requestPermission()
            return
        }
        
        OnitPanelManager.shared.state.launchPanel()
    }
}

#Preview {
    TetheredButton()
}
