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
    @Default(.incognitoModeEnabled) var incognitoModeEnabled
    
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
                Spacer()
                    .frame(width: 60)
            } else {
                esc
            }
            
            add
            Spacer()
            languageModel
            if isRegularApp {
                fitActiveWindowButton
            }
            localMode
            incognitoMode
            history
            settings
            
            if !isRegularApp {
                resize
            }
        }
        .foregroundStyle(.gray200)
        .padding(.horizontal, 14)
        .padding(.vertical, 2)
        .background {
            escListener
        }
        .background {
            heightListener
        }
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
    
    var fitActiveWindowButton: some View {
        Button {
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
        } label: {
            let image: ImageResource = fitActiveWindow ? .windowFit : .windowUnfit
            
            Image(image)
                .renderingMode(.template)
                .foregroundStyle(.gray200)
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
        .tooltip(prompt: fitActiveWindowPrompt)
    }

    var resize: some View {
        Button {
            model.togglePanelSize()
        } label: {
            Image(.resize)
                .renderingMode(.template)
                .padding(3)
        }
        .tooltip(
            prompt: "Resize Window",
            shortcut: .keyboardShortcuts(.resizeWindow)
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

    @ViewBuilder
    var languageModel: some View {
        @Bindable var model = model

        Button {
            OverlayManager.shared.captureClickPosition()
            OverlayManager.shared.showOverlay(model: model, content: ModelSelectionView())
        } label: {
            HStack(spacing: 0) {
                Text(
                    mode == .local
                        ? (localModel?.split(separator: ":").first.map(String.init)
                            ?? "Choose model")
                        : (remoteModel?.displayName ?? "Choose model")
                )
                .appFont(.medium13)
                .padding(.leading, 2)
                Image(.smallChevDown)
                    .renderingMode(.template)
            }
            .padding(2)
            .contentShape(.rect)
            .background {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.clear)
            }
        }
        .tooltip(prompt: "Change model")
    }

    var add: some View {
        HStack(spacing: 0) {
            Button {
                model.newChat()
            } label: {
                Image(.circlePlus)
                    .renderingMode(.template)
                    .padding(2)
            }
            .tooltip(prompt: "New Chat", shortcut: .keyboardShortcuts(.newChat))
            
            Button {
                model.newChat()
                
                SystemPromptState.shared.shouldShowSelection = true
                SystemPromptState.shared.shouldShowSystemPrompt = true
            } label: {
                Image(.smallChevDown)
                    .renderingMode(.template)
                    .padding(2)
            }
            .onHover(perform: { isHovered in
                if isHovered && model.currentChat?.systemPrompt == nil && !SystemPromptState.shared.shouldShowSystemPrompt {
                    SystemPromptState.shared.shouldShowSystemPrompt = true
                }
            })
            .tooltip(prompt: "Start new Chat with system prompt")
        }
    }

    var localMode: some View {
        Button {
            mode = mode == .local ? .remote : .local
        } label: {
            Image(mode == .local ? .localModeActive : .localMode)
                .renderingMode(.template)
                .padding(2)
                .foregroundColor(mode == .local ? .limeGreen : .gray200)
        }
        .tooltip(prompt: "Local Mode", shortcut: .keyboardShortcuts(.toggleLocalMode))
    }
    
    var incognitoMode: some View {
        Button {
            incognitoModeEnabled.toggle()
            model.newChat()
        } label: {
            Image(incognitoModeEnabled ? .incogOn : .incogOff)
                .renderingMode(.template)
                .padding(4)
                .foregroundColor(incognitoModeEnabled ? .blue400 : .gray200)
        }
        .tooltip(prompt: "Incognito mode (auto-context off)")
    }

    var showHistoryBinding: Binding<Bool> {
        Binding(
            get: { self.model.showHistory },
            set: { self.model.showHistory = $0 }
        )
    }
    
    var history: some View {
        Button {
            model.showHistory.toggle()
        } label: {
            Image(.history)
                .renderingMode(.template)
                .padding(2)
        }
        .tooltip(prompt: "History")
        .popover(
            isPresented: showHistoryBinding,
            arrowEdge: .bottom
        )  {
            HistoryView()
        }
    }

    var settings: some View {
        Button {
            NSApp.activate()
            if NSApp.isActive {
                model.setSettingsTab(tab: .general)
                openSettings()
            }
        } label: {
            Image(.settingsCog)
                .renderingMode(.template)
                .padding(2)
        }
        .tooltip(prompt: "Settings", shortcut: .none)
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
