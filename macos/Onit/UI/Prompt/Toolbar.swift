//
//  Toolbar.swift
//  Onit
//
//  Created by Benjamin Sage on 9/20/24.
//

import Defaults
import KeyboardShortcuts
import SwiftUI

struct Toolbar: View {
    @Environment(\.model) var model
    @Environment(\.openSettings) var openSettings
    
    @ObservedObject private var featureFlagsManager = FeatureFlagManager.shared
    
    @Default(.mode) var mode
    @Default(.remoteModel) var remoteModel
    @Default(.localModel) var localModel
    @Default(.isRegularApp) var isRegularApp
    @Default(.fitActiveWindow) var fitActiveWindow
    
    private var isAccessibilityFlagsEnabled: Bool {
        featureFlagsManager.accessibility && featureFlagsManager.accessibilityAutoContext
    }
    
    private var isAccessibilityAuthorized: Bool {
        model.accessibilityPermissionStatus == .granted
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
        
        return fitActiveWindow ? "Detach from active window" : "Fit to active window"
    }

    var body: some View {
        HStack(spacing: 4) {
            if isRegularApp {
                Spacer().frame(width: 60)
            } else {
                esc
            }
            
            add
            
            Spacer()
            
            if isRegularApp { fitActiveWindowButton }
            localMode
            history
            settings
            
            if !isRegularApp {
                resize
            }
        }
        .frame(height: 32, alignment: .center)
        .foregroundStyle(.gray200)
        .padding(.horizontal, 14)
        .padding(.top, 4)
        .padding(.bottom, 2)
        .background { escListener }
        .background { heightListener }
    }

    var esc: some View {
        Button {
            model.closePanel()
        } label: {
            Text("ESC")
                .appFont(.medium13)
                .padding(4)
        }
        .tooltip(prompt: "Close Onit", shortcut: .keyboardShortcuts(.escape))
    }

    // Empty view for layout purposes
    var escListener: some View {
        EmptyView()
    }
    
    func fitToActiveWindow() {
        guard isAccessibilityFlagsEnabled else {
            model.setSettingsTab(tab: .accessibility)
            openSettings()
            return
        }
        guard isAccessibilityAuthorized else {
            AccessibilityPermissionManager.shared.requestPermission()
            return
        }
        
        fitActiveWindow.toggle()
    }
    var fitActiveWindowButton: some View {
        IconButton(
            icon: fitActiveWindow ? .windowFit : .windowUnfit,
            action: { fitToActiveWindow() },
            isActive: fitActiveWindow,
            tooltipPrompt: fitActiveWindowPrompt
        )
        .overlay(
            Group {
                if !isAccessibilityFlagsEnabled || !isAccessibilityAuthorized {
                    Rectangle()
                        .fill(.black)
                        .frame(width: 24, height: 4)
                        .rotationEffect(.degrees(45))
                        .offset(y: 0)
                    
                    Rectangle()
                        .fill(.gray200)
                        .frame(height: 2)
                        .rotationEffect(.degrees(45))
                        .offset(y: 0)
                }
            }
        )
    }

    var resize: some View {
        IconButton(
            icon: .resize,
            action: { model.togglePanelSize() },
            isActive: Defaults[.isPanelExpanded],
            tooltipPrompt: "Resize Window",
            tooltipShortcut: .keyboardShortcuts(.resizeWindow)
        )
    }

    // Helper function to create a picker for models
    private func createModelPicker<T: Hashable>(
        title: String,
        selection: Binding<T?>,
        models: [T],
        currentModel: T?
    ) -> some View {
        Picker(title, selection: selection) {
            ForEach(models, id: \.self) { model in
                HStack {
                    Text("\(model)")
                    Spacer()
                    if model == currentModel {
                        Text("default")
                            .italic()
                            .foregroundStyle(.gray400)
                    }
                }
                .tag(model as T?)
            }
        }
        .pickerStyle(.inline)
    }

    var add: some View {
        HStack(spacing: 0) {
            IconButton(
                icon: .circlePlus,
                action: { model.newChat() },
                tooltipPrompt: "New Chat",
                tooltipShortcut: .keyboardShortcuts(.newChat)
            )
            
            IconButton(
                icon: .smallChevDown,
                action: {
                    model.newChat()
                    SystemPromptState.shared.shouldShowSelection = true
                    SystemPromptState.shared.shouldShowSystemPrompt = true
                },
                isActive: SystemPromptState.shared.shouldShowSelection,
                tooltipPrompt: "Start new Chat with system prompt"
            )
            .onHover(perform: { isHovered in
                if isHovered && model.currentChat?.systemPrompt == nil && !SystemPromptState.shared.shouldShowSystemPrompt {
                    SystemPromptState.shared.shouldShowSystemPrompt = true
                }
            })
        }
    }

    func toggleMode() {
        mode = mode == .local ? .remote : .local
    }
    var localMode: some View {
        IconButton(
            icon: mode == .local ? .localModeActive : .localMode,
            action: { toggleMode() },
            isActive: mode == .local,
            activeColor: .limeGreen,
            tooltipPrompt: "Local Mode",
            tooltipShortcut: .keyboardShortcuts(.toggleLocalMode)
        )
    }

    var showHistoryBinding: Binding<Bool> {
        Binding(
            get: { self.model.showHistory },
            set: { self.model.showHistory = $0 }
        )
    }
    var history: some View {
        IconButton(
            icon: .history,
            action: { model.showHistory.toggle() },
            isActive: model.showHistory,
            tooltipPrompt: "History"
        )
        .popover(
            isPresented: showHistoryBinding,
            arrowEdge: .bottom
        )  {
            HistoryView()
        }
    }

    func openSettingsWindow() {
        NSApp.activate()
        if NSApp.isActive {
            model.setSettingsTab(tab: .general)
            openSettings()
        }
    }
    var settings: some View {
        IconButton(
            icon: .settingsCog,
            action: { openSettingsWindow() },
            tooltipPrompt: "Settings"
        )
    }

    var heightListener: some View {
        GeometryReader { proxy in
            Color.clear
                .onAppear {
                    model.headerHeight = proxy.size.height
                }
                .onChange(of: proxy.size.height) { _, new in
                    model.headerHeight = new
                }
        }
    }
}

#Preview {
    Toolbar()
}
