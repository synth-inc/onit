//
//  Hint+FeatureButtons.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Types
 * Variables: "Show" Booleans
 * Public Functions
 * Private Functions
 * Child Components: Public
 * Child Components: Private
 */

import Defaults
import SwiftUI

extension Hint {
    // MARK: - Types

    enum HoveredFeatureButton: Equatable {
        case sidebar
        case update
    }

    // MARK: - Variables: "Show" Booleans

    private var showSidebarButton: Bool {
        return enableSidebar
    }

    var showUpdateButton: Bool {
        return appState.isUpdateAvailable
    }

    // MARK: - Public Functions

    func installUpdate() {
        guard !isDragging else { return }
        Defaults[.dismissedUpdateAlertVersion] = appState.availableUpdateVersion ?? ""
        hideMoreMenu()
        appState.checkForAvailableUpdateWithDownload()
    }

    // MARK: - Private Functions

    private func showSidebar() {
        guard !isDragging else { return }
        hideMoreMenu()
        onSidebarClick()
    }

    // MARK: - Child Components: Public

    var logoButton: some View {
        FeatureButton(icon: .noodle) {}
            .allowsHitTesting(false)
    }

    var moreMenuButton: some View {
        FeatureButton(
            icon: .dots,
            width: nil
        ) {
            toggleMoreMenu()
        }
        .padding(.horizontal, Self.moreMenuButtonHorizontalPadding)
    }

    @ViewBuilder
    var sidebarButton: some View {
        if showSidebarButton {
            FeatureButton(
                icon: .sidekick,
                hoveredButton: .sidebar,
                currentHoveredButton: $hoveredFeatureButton
            ) {
                showSidebar()
            }
        }
    }

    @ViewBuilder
    var updateButton: some View {
        if showUpdateButton {
            FeatureButton(
                icon: .update,
                shouldShowProminence: true,
                hoveredButton: .update,
                currentHoveredButton: $hoveredFeatureButton
            ) {
                installUpdate()
            }
        }
    }

    // MARK: - Child Components: Private

    private struct FeatureButton: View {
        var icon: ImageResource? = nil
        var systemName: String? = nil
        var width: CGFloat? = Hint.featureButtonSize
        var height: CGFloat? = Hint.featureButtonSize
        var hasError: Bool = false
        var shouldShowProminence: Bool = false
        var disabled: Bool = false
        var hoveredButton: HoveredFeatureButton? = nil
        var currentHoveredButton: Binding<HoveredFeatureButton?> = .constant(nil)
        let action: () -> Void

        @State private var isHovering: Bool = false

        var foregroundColor: Color {
            if hasError {
                return Color.S_0
            } else if shouldShowProminence {
                return Color.lime400
            } else {
                return isHovering ? Color.S_1 : Color.T_1
            }
        }

        var backgroundColor: Color {
            if hasError {
                if isHovering {
                    return Color.red500.opacity(0.3)
                } else {
                    return Color.red500.opacity(0.15)
                }
            } else if shouldShowProminence {
                if isHovering {
                    return Color.lime400.opacity(0.3)
                } else {
                    return Color.lime400.opacity(0.15)
                }
            } else {
                if isHovering {
                    return Color.T_9
                } else {
                    return Color.clear
                }
            }
        }

        var borderColor: Color {
            if hasError {
                return Color.red500
            } else if shouldShowProminence {
                return Color.lime400
            } else {
                return Color.clear
            }
        }

        var body: some View {
            Button {
                if !disabled {
                    action()
                }
            } label: {
                iconView
                    .foregroundColor(foregroundColor)
                    .frame(
                        width: width,
                        height: height
                    )
                    .contentShape(Rectangle())
                    .opacity(disabled ? 0.5 : 1.0)
            }
            .buttonStyle(PlainButtonStyle())
            .background(disabled ? Color.clear : backgroundColor)
            .addBorder(
                cornerRadius: 999,
                stroke: borderColor
            )
            .onHover { isHovering in
                self.isHovering = isHovering

                if isHovering {
                    currentHoveredButton.wrappedValue = hoveredButton
                } else if currentHoveredButton.wrappedValue == hoveredButton {
                    currentHoveredButton.wrappedValue = nil
                }
            }
        }
        
        @ViewBuilder
        private var iconView: some View {
            if let systemName = systemName {
                Image(systemName: systemName)
                    .font(.system(size: Hint.featureButtonIconSize, weight: .medium))
                    .frame(
                        width: Hint.featureButtonIconSize,
                        height: Hint.featureButtonIconSize
                    )
            } else if let icon = icon {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(
                        width: Hint.featureButtonIconSize,
                        height: Hint.featureButtonIconSize
                    )
            }
        }
    }
}
