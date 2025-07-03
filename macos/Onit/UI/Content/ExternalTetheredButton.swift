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
    
    @Default(.tetheredButtonHiddenApps) var tetheredButtonHiddenApps
    @Default(.tetheredButtonHideAllApps) var tetheredButtonHideAllApps
    @Default(.tetheredButtonHideAllAppsTimerDate) var tetheredButtonHideAllAppsTimerDate // Currently hides for one hour.
    
    // MARK: - Initializers

    static let width: CGFloat = 40
    static let height: CGFloat = 40
    static let containerWidth: CGFloat = width * 2
    static let containerHeight: CGFloat = height * 2
    static let borderWidth: CGFloat = 1.5
    
    var onClick: () -> Void
    var onDrag: ((CGFloat) -> Void)?
    
    // MARK: - State
    
    @State private var isHoveringButton: Bool = false
    @State private var isPressed: Bool = false
    @State private var isDragging: Bool = false
    @State private var dragStartTime: Date? = nil
    
    @State private var showRightClickMenu: Bool = false
    @State private var rightClickListener: Any? = nil
    
    @State private var hideAllAppsTimer: Timer? = nil
    
    // MARK: - Private Variables
    
    private var fitActiveWindowPrompt: String {
        return "Launch Onit"
    }
    
    private var capturedHighlightedText: Bool {
        return windowState?.pendingInput != nil
    }
    
    private var capturedForegroundWindow: Bool {
        windowState?.foregroundWindow != nil
    }
    
    private var foregroundWindowIcon: NSImage? {
        if let foregroundWindow = windowState?.foregroundWindow {
            return WindowHelpers.getWindowIcon(window: foregroundWindow.element)
        } else {
            return nil
        }
    }
    
    private var foregroundWindowAppName: String? {
        if let foregroundWindow = windowState?.foregroundWindow {
            return WindowHelpers.getWindowAppName(window: foregroundWindow.element)
        } else {
            return nil
        }
    }
    
    private var hideAllAppsCountdownIsActive: Bool {
        hideAllAppsTimer != nil && tetheredButtonHideAllAppsTimerDate != nil
    }
    private var isHidingAllApps: Bool {
        tetheredButtonHideAllApps || hideAllAppsCountdownIsActive
    }
    
    private var foregroundWindowIconHidden: Bool {
        if let appName = foregroundWindowAppName,
           checkCurrentAppIsHidden(appName)
        {
            return true
        } else {
            return isHidingAllApps
        }
    }
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                if dragStartTime == nil {
                    dragStartTime = Date()
                }
                
                if let startTime = dragStartTime,
                   Date().timeIntervalSince(startTime) > 0.1
                {
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
    
    // MARK: - Body
    
    var body: some View {
        VStack {
            Button(action: tetherAction) {
                if dragStartTime != nil {
                    icon(.drag)
                } else if capturedHighlightedText {
                    icon(.text)
                } else if let foregroundWindowIcon = foregroundWindowIcon {
                    if foregroundWindowIconHidden {
                        icon(.smirk)
                    } else {
                        Image(nsImage: foregroundWindowIcon)
                            .resizable()
                            .frame(
                                width: 22,
                                height: 22
                            )
                            .frame(
                                width: Self.width,
                                height: Self.height
                            )
                    }
                } else {
                    icon(.dots)
                }
            }
            .buttonStyle(
                ExternalTetheredButtonStyle(
                    dragStartTime: $dragStartTime,
                    isHovering: $isHoveringButton,
                    tooltipText: fitActiveWindowPrompt
                )
            )
            .offset(x: capturedHighlightedText ? Self.borderWidth : 0)
            .simultaneousGesture(dragGesture)
            .onAppear {
                initializeRightClickListener()
                initializeHideAllAppsTimer()
            }
            .onDisappear {
                clearRightClickListener()
                clearHideAllAppsTimer()
            }
            .popover(
                isPresented: $showRightClickMenu,
                arrowEdge: .trailing
            ) {
                rightClickMenu
            }
        }
        .frame(
            width: Self.containerWidth,
            height: Self.containerHeight,
            alignment: .trailing
        )
        .offset(x: 1)
    }
}

// MARK: - Child Components

extension ExternalTetheredButton {
    private func icon(_ imageResource: ImageResource) -> some View {
        Image(imageResource)
            .renderingMode(.template)
            .foregroundColor(.white)
            .frame(
                width: Self.width,
                height: Self.height
            )
    }
    
    private var rightClickMenu: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Onit Handle")
                .styleText(
                    size: 13,
                    weight: .regular,
                    color: .gray100
                )
                .padding(.top, 4)
                .padding(.horizontal, 8)
            
            VStack(alignment: .leading, spacing: 2) {
                if let appName = foregroundWindowAppName {
                    let appIsHidden = checkCurrentAppIsHidden(appName)
                    
                    TextButton(
                        iconSize: 18,
                        icon: .removeCross,
                        text: "\(appIsHidden ? "Show" : "Hide") \(appName)"
                    ) {
                        toggleHideCurrentForegroundWindowIcon(appName: appName)
                    }
                }
                
                TextButton(
                    iconSize: 18,
                    disabled: tetheredButtonHideAllAppsTimerDate != nil,
                    icon: .timerSleep,
                    text: tetheredButtonHideAllAppsTimerDate == nil ? "Hide Everywhere for 1h" : "Hiding for 1h..."
                ) {
                    toggleHideForegroundWindowIconsForOneHour()
                }
                .allowsHitTesting(tetheredButtonHideAllAppsTimerDate == nil)
                
                TextButton(
                    iconSize: 16,
                    icon: .box,
                    text: "\(isHidingAllApps ? "Show" : "Hide") Current App Icon"
                ) {
                    toggleHideForegroundWindowIcons()
                }
            }
        }
        .padding(8)
        .background(.gray900)
    }
}

// MARK: - Private Functions

extension ExternalTetheredButton {
    private func tetherAction() {
        guard !isDragging else { return }
        
        onClick()
    }
    
    private func checkCurrentAppIsHidden(_ appName: String) -> Bool {
        tetheredButtonHiddenApps[appName] != nil
    }
    
    // MARK: - Right-Click Handlers
    
    private func initializeRightClickListener() {
        rightClickListener = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { event in
            if let window = event.window,
               let contentView = window.contentView
            {
                contentView.convert(
                    event.locationInWindow,
                    from: nil
                )
                
                /// The popover's NSWindow doesn't get painted as quickly as `showRightClickMenu` is set to `true.`
                /// This is required to allow the popover to be set to focus so that users don't have to double-click to invoke the menu's buttons.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    NSApp.activate(ignoringOtherApps: true)
                    
                    if let popoverWindow = NSApp.windows.last {
                        popoverWindow.makeKeyAndOrderFront(nil)
                    }
                }
                
                showRightClickMenu = true
            }
            
            return event
        }
    }

    private func clearRightClickListener() {
        guard let listener = rightClickListener else { return }
        
        NSEvent.removeMonitor(listener)
        rightClickListener = nil
    }
    
    // MARK: - Timer Handlers
    
    private func initializeHideAllAppsTimer() {
        let dateNow = Date()
        
        guard let hideAllAppsTimerDate = tetheredButtonHideAllAppsTimerDate,
              hideAllAppsTimerDate >= dateNow
        else {
            tetheredButtonHideAllAppsTimerDate = nil
            return
        }
        
        hideAllAppsTimer = Timer.scheduledTimer(
            withTimeInterval: hideAllAppsTimerDate.timeIntervalSince(dateNow),
            repeats: false
        ) { _ in
            Task { @MainActor in
                tetheredButtonHideAllAppsTimerDate = nil
                tetheredButtonHideAllApps = false
            }
        }
    }
        
    private func clearHideAllAppsTimer() {
        hideAllAppsTimer?.invalidate()
        hideAllAppsTimer = nil
    }
    
    // MARK: - Right-Click Menu Button Handlers
    
    private func toggleHideCurrentForegroundWindowIcon(appName: String) {
        let appIsHidden = checkCurrentAppIsHidden(appName)
        
        if appIsHidden {
            tetheredButtonHiddenApps.removeValue(forKey: appName)
        } else {
            tetheredButtonHiddenApps[appName] = true
        }
        
        showRightClickMenu = false
    }
    
    private func toggleHideForegroundWindowIconsForOneHour() {
        let oneHourInSeconds: TimeInterval = 3600
        tetheredButtonHideAllAppsTimerDate = Date(timeIntervalSinceNow: oneHourInSeconds)
        
        clearHideAllAppsTimer()
        initializeHideAllAppsTimer()
        
        tetheredButtonHideAllApps = true

        showRightClickMenu = false
    }
    
    private func toggleHideForegroundWindowIcons() {
        tetheredButtonHideAllApps.toggle()
        
        clearHideAllAppsTimer()
        tetheredButtonHideAllAppsTimerDate = nil
        
        showRightClickMenu = false
    }
}

#Preview {
    ExternalTetheredButton {}
}
