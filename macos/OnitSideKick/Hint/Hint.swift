//
//  Hint.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Environments
 * Defaults
 * Properties
 * Observations
 * States
 * Private Variables
 * Body
 */

import Defaults
import Foundation
import SwiftUI

struct Hint: View {
    // MARK: - Environments

    @Environment(\.appState) var appState
    @Environment(\.windowState) var windowState

    // MARK: - Defaults

    @Default(.tetheredButtonHiddenApps) var tetheredButtonHiddenApps
    @Default(.tetheredButtonHideAllApps) var tetheredButtonHideAllApps
    @Default(.tetheredButtonHideAllAppsTimerDate) var tetheredButtonHideAllAppsTimerDate
    @Default(.tetheredButtonShowAppIcons) var tetheredButtonShowAppIcons
    @Default(.enableSidebar) var enableSidebar

    // MARK: - Properties

    var onSidebarClick: () -> Void
    var onDrag: (CGFloat) -> Void

    // MARK: - Observations

    @ObservedObject var hintManager = HintManager.shared

    @ObservedObject var accessibilityPermissionManager = AccessibilityPermissionManager.shared
    /// Commented out for now until non-AX becomes the default state.
//    @ObservedObject private var screenRecordingPermissionManager = ScreenRecordingPermissionManager.shared
    
    @ObservedObject private var localization = LocalizationManager.shared

    // MARK: - States
    
    @State var shouldShowMoreMenu: Bool = false
    @State var isDragging: Bool = false
    @State private var dragStartTime: Date? = nil
    @State var hideAllAppsTimer: Timer? = nil
    @State var clickOutsideLocalMonitor: Any? = nil
    @State var clickOutsideGlobalMonitor: Any? = nil
    @State var hoveredFeatureButton: HoveredFeatureButton? = nil

    // MARK: - Private Variables

    private var shouldExpandHint: Bool {
        let isHovered = hintManager.isHintHovered

        return
            shouldShowMoreMenu ||
            isHovered
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Self.outerHStackSpacing) {
            if shouldExpandHint {
                moreMenuButton

                HStack(alignment: .center, spacing: Self.innerHStackSpacing) {
                    sidebarButton
                    updateButton
                }
            } else {
                logoButton
            }
        }
        .padding(Self.hintPadding)
        .background(
            ZStack {
                Backgrounds.BrushedGlass()
                Color.S_10.opacity(0.6)
            }
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 999,
                    bottomLeadingRadius: 999,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 999,
                bottomLeadingRadius: 999,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0
            )
            .strokeBorder(Color.T_5, lineWidth: 1)
            .mask(
                HStack(spacing: 0) {
                    Color.black
                    Color.clear.frame(width: 1)
                }
            )
        )
        .fixedSize()
        .simultaneousGesture(
            DragGesture()
                .onChanged { value in
                    if dragStartTime == nil {
                        dragStartTime = Date()
                    }

                    if let startTime = dragStartTime,
                       Date().timeIntervalSince(startTime) > 0.1
                    {
                        if !isDragging {
                            isDragging = true
                        }
                        onDrag(value.translation.height)
                    }
                }
                .onEnded { _ in
                    dragStartTime = nil

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isDragging = false
                    }
                }
        )
        .onAppear {
            initializeHideAllAppsTimer()

            /// Show initial pop-up if needed.
            if let activePopUpMessageType = self.activePopUpMessageType,
                !shouldShowMoreMenu
            {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    showPopUpMessage(type: activePopUpMessageType)
                }
            }
        }
        .onDisappear {
            clearHideAllAppsTimer()
            removeClickOutsideMonitor()
            hintManager.hideMoreMenu()
        }
        .onChange(of: activePopUpMessageType) { _, newPopUpMessageType in
            if let popUpMessageType = newPopUpMessageType {
                /// Show pop-up when we're not showing the more menu so that they don't clash.
                if !shouldShowMoreMenu {
                    /// Defer to the next run loop cycle so that we can measure accurate more menu dimensions.
                    /// This in turn allows us to more accurately position the pop-up messages.
                    DispatchQueue.main.async {
                        showPopUpMessage(type: popUpMessageType)
                    }
                }
            } else {
                /// Hide pop-up if there is no active pop-up message to show.
                if !shouldShowMoreMenu {
                    hintManager.hideMoreMenu()
                }
            }
        }
        .onChange(of: hoveredFeatureButton) { _, currentHoveredFeatureButton in
            let shouldShowHoverPopUpMessage =
                currentHoveredFeatureButton != nil &&
                activePopUpMessageType == .hover &&
                !shouldShowMoreMenu

            if shouldShowHoverPopUpMessage {
                showPopUpMessage(type: .hover)
            }
        }
        .id(localization.currentLanguage)
    }
}
