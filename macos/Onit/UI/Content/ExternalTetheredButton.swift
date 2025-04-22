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
    
    static let width: CGFloat = 19
    static let height: CGFloat = 53
    static let containerWidth: CGFloat = width * 2
    static let containerHeight: CGFloat = height * 2
    static let borderWidth: CGFloat = 1.5
    
    var onDrag: ((CGFloat) -> Void)?
    
    @State private var hovering = false
    @State private var isDragging = false
    @State private var dragStartTime: Date?
    
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
        
        return "Launch Onit"
    }
    
    private var containsInput: Bool {
        return windowState.pendingInput != nil
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
        
        guard isAccessibilityFlagsEnabled else {
            appState.setSettingsTab(tab: .accessibility)
            openSettings()
            return
        }
        guard isAccessibilityAuthorized else {
            AccessibilityPermissionManager.shared.requestPermission()
            return
        }

        if let state = TetherAppsManager.shared.tetherButtonPanelState {
            state.launchPanel()
        } else {    
            print("Couldn't find activeTrackedWindow")
        }
    }
}

#Preview {
    ExternalTetheredButton()
}
