//
//  Hint+PopUpMessages.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Variables: Active Pop-Up Message Type
 * Private Variables
 * Public Functions
 * Child Components
 * Simple Pop-Up Message View
 * Callback Pop-Up Message View
 * Don't Show Toggle Button
 * Auto-Dismiss Timer Bar
 */

import Defaults
import KeyboardShortcuts
import SwiftUI

extension Hint {
    // MARK: - Variables: Active Pop-Up Message Type

    var activePopUpMessageType: HintPopUpMessageType? {
        if let activePopUpType = hintManager.activePopUpType {
            return activePopUpType
        } else if shouldShowOnHoverPopUpMessage {
            return .hover
        } else {
            return nil
        }
    }

    // MARK: - Private Variables

    private var currentFeatureButtonHoverText: (
        title: String,
        caption: String?
    )? {
        guard let hoveredFeatureButton = self.hoveredFeatureButton
        else {
            return nil
        }

        switch hoveredFeatureButton {
        case .sidebar:
            return (String.localized("Open Sidekick", table: "MenuBar"), KeyboardShortcuts.Name.launch.shortcutText)
        case .update:
            return (String.localized("Install New Update", table: "MenuBar"), nil)
        }
    }

    private var shouldShowOnHoverPopUpMessage: Bool {
        return hoveredFeatureButton != nil && !shouldShowMoreMenu
    }

    // MARK: - Public Functions

    func showPopUpMessage(type: HintPopUpMessageType) {
        switch type {
        case .accessibilityLost:
            hintManager.showMoreMenu(swiftUIView: accessibilityLostPopUpMessageView)
        /// Commented out for now until non-AX becomes the default state.
//        case .screenRecordingLost:
//            hintManager.showMoreMenu(swiftUIView: screenRecordingLostPopUpMessageView)
        case .updateAvailable:
            hintManager.showMoreMenu(swiftUIView: updateAvailablePopUpMessageView)
        case .hover:
            hintManager.showMoreMenu(swiftUIView: onHoverPopUpMessageView)
        }
    }
    
    // MARK: - Child Components
    
    private var accessibilityLostPopUpMessageView: some View {
        CallbackPopUpMessageView(
            text: String.localized("Accessibility access required", table: "MenuBar"),
            systemIcon: .init(name: "exclamationmark.circle"),
            autoDismissDuration: HintPopUpMessageType.accessibilityLost.autoDismissDuration,
            callback: .init(
                text: String.localized("Grant Access", table: "MenuBar"),
                action: {
                    accessibilityPermissionManager.requestPermission()
                }
            )
        )
    }

    /// Commented out for now until non-AX becomes the default state.
//    private var screenRecordingLostPopUpMessageView: some View {
//        CallbackPopUpMessageView(
//            text: String.localized("Screen recording access required"),
//            systemIcon: .init(name: "exclamationmark.circle"),
//            autoDismissDuration: HintPopUpMessageType.screenRecordingLost.autoDismissDuration,
//            callback: .init(
//                text: String.localized("Grant Access", table: "MenuBar"),
//                action: {
//                    Task {
//                        _ = await self.screenRecordingPermissionManager.requestScreenRecordingPermission()
//                    }
//                }
//            )
//        )
//    }

    private var updateAvailablePopUpMessageView: some View {
        CallbackPopUpMessageView(
            text: String.localized("A new update is available", table: "MenuBar"),
            systemIcon: .init(
                name: "arrow.down.circle",
                color: Color.lime400
            ),
            autoDismissDuration: HintPopUpMessageType.updateAvailable.autoDismissDuration,
            callback: .init(
                text: String.localized("Install Update", table: "MenuBar"),
                action: {
                    installUpdate()
                }
            ),
            closeAction: {
                hintManager.dismissPopUp()
            }
        ) {
            DontShowToggleButton(defaultsKey: .showHintUpdateAvailableAlert)
        }
    }

    @ViewBuilder
    private var onHoverPopUpMessageView: some View {
        if let hoverText = currentFeatureButtonHoverText {
            SimplePopUpMessageView {
                HStack(alignment: .center, spacing: 4) {
                    Text(hoverText.title)
                        .styleText(
                            size: 13,
                            weight: .regular
                        )
                    if let caption = hoverText.caption {
                        Text(caption)
                            .styleText(
                                size: 13,
                                weight: .regular,
                                color: Color.S_0.opacity(0.7)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Simple Pop-Up Message View
    
    private struct SimplePopUpMessageView<Children: View>: View {
        let children: () -> Children
        
        var body: some View {
            children()
                .padding(12)
                .frame(maxWidth: 256)
                .background(Color.smoke)
                .addBorder(
                    cornerRadius: 16,
                    stroke: Color.T_4
                )
        }
    }
    
    // MARK: - Callback Pop-Up Message View

    private struct CallbackPopUpMessageView<Children: View>: View {
        struct SystemIcon {
            let name: String
            var color: Color = Color.red500
        }
        struct Callback {
            let text: String
            let action: () -> Void
        }

        private let text: String
        private let subtext: String?
        private let systemIcon: SystemIcon?
        private let autoDismissDuration: Duration?
        private let callback: Callback?
        private let closeAction: (() -> Void)?
        @ViewBuilder private let children: () -> Children

        init(
            text: String,
            subtext: String? = nil,
            systemIcon: SystemIcon? = nil,
            autoDismissDuration: Duration? = nil,
            callback: Callback? = nil,
            closeAction: (() -> Void)? = nil,
            @ViewBuilder children: @escaping () -> Children = { EmptyView() }
        ) {
            self.text = text
            self.subtext = subtext
            self.systemIcon = systemIcon
            self.autoDismissDuration = autoDismissDuration
            self.callback = callback
            self.closeAction = closeAction
            self.children = children
        }

        @State private var isHoveredCloseButton: Bool = false
        
        var body: some View {
            VStack(alignment: .center, spacing: 10) {
                if let systemIcon = self.systemIcon {
                    Image(systemName: systemIcon.name)
                        .font(.system(
                            size: 16,
                            weight: .medium
                        ))
                        .foregroundColor(systemIcon.color)
                }
                
                VStack(alignment: .center, spacing: 4) {
                    Text(text)
                        .styleText(
                            size: 15,
                            weight: .regular,
                            align: .center
                        )
                    
                    if let subtext = self.subtext {
                        Text(subtext)
                            .styleText(
                                size: 13,
                                weight: .regular,
                                color: Color.T_1,
                                align: .center
                            )
                    }
                }

                if let callback = self.callback {
                    TextButton(
                        text: callback.text,
                        colorConfig: .init(
                            text: Color.S_10,
                            background: Color.S_0
                        )
                    ) {
                        callback.action()
                    }
                }

                children()
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 28)
            .background(Color.S_10.opacity(0.65))
            .background(Backgrounds.BrushedGlass())
            .overlay(alignment: .bottom) {
                if let autoDismissDuration = self.autoDismissDuration {
                    AutoDismissTimerBar(duration: autoDismissDuration)
                }
            }
            .addBorder(
                cornerRadius: 16,
                stroke: Color.T_4
            )
            .fixedSize()
            .overlay(alignment: .topTrailing) {
                closeButton
            }
        }
        
        @ViewBuilder
        private var closeButton: some View {
            if let closeAction = self.closeAction {
                Button {
                    closeAction()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(
                            size: 13,
                            weight: .medium
                        ))
                        .foregroundColor(isHoveredCloseButton ? Color.S_0 : Color.T_3)
                        .frame(
                            width: 20,
                            height: 20,
                            alignment: .center
                        )
                        .clipShape(Circle())
                        .addAnimation(dependency: isHoveredCloseButton)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(8)
                .onHover { isHovered in
                    isHoveredCloseButton = isHovered
                }
            }
        }
    }
    
    // MARK: - Don't Show Toggle Button
    
    private struct DontShowToggleButton: View {
        let defaultsKey: Defaults.Key<Bool>
        
        init(defaultsKey: Defaults.Key<Bool>) {
            self.defaultsKey = defaultsKey
            self._isEnabled = State(initialValue: Defaults[defaultsKey])
        }

        @State private var isEnabled: Bool
        @State private var isHovered: Bool = false
        @State private var isPressed: Bool = false
        
        private var background: Color {
            if isEnabled {
                return Color.T_7
            } else {
                return Color.S_0
            }
        }

        var body: some View {
            HStack(alignment: .center, spacing: 8) {
                HStack(alignment: .center, spacing: 0) {
                    if !isEnabled {
                        Image(systemName: "checkmark")
                            .styleText(
                                size: 10,
                                color: Color.S_10
                            )
                    }
                }
                .frame(width: 16, alignment: .center)
                .frame(height: 16, alignment: .center)
                .addButtonEffects(
                    background: background,
                    hoverBackground: background.opacity(0.7),
                    cornerRadius: 4,
                    isHovered: $isHovered,
                    isPressed: $isPressed
                ) {
                    Defaults[defaultsKey].toggle()
                }
                .addBorder(
                    cornerRadius: 4,
                    stroke: Color.T_4
                )

                Text(String.localized("Don't show again", table: "MenuBar"))
                    .styleText(
                        size: 13,
                        weight: .regular,
                        color: Color.T_1
                    )
            }
            .onReceive(Defaults.publisher(defaultsKey).map(\.newValue)) { newValue in
                isEnabled = newValue
            }
        }
    }
    
    // MARK: - Auto-Dismiss Timer Bar

    private struct AutoDismissTimerBar: View {
        let duration: Duration

        @State private var progress: CGFloat = 1

        var body: some View {
            GeometryReader { geometry in
                LinearGradient(
                    stops: [
                        .init(color: Color.white, location: 0),
                        .init(color: Color.white, location: 0.85),
                        .init(color: Color.white.opacity(0), location: 1)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(
                    width: geometry.size.width * progress,
                    height: 2
                )
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
            }
            .frame(height: 2)
            .onAppear {
                let seconds = Double(duration.components.seconds)
                    + Double(duration.components.attoseconds) / 1e18

                withAnimation(.linear(duration: seconds)) {
                    progress = 0
                }
            }
        }
    }
}
