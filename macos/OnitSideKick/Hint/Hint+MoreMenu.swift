//
//  Hint+MoreMenu.swift
//  Onit
//
//  Created by Loyd Kim on 1/29/26.
//

/*
 * Functions: Click Outside Monitor
 * Functions: Visibility Toggles
 * Private Functions
 * Child Components
 */

import SwiftUI

extension Hint {
    // MARK: - Functions: Click Outside Monitor
    
    private func setupClickOutsideMonitor() {
        removeClickOutsideMonitor()
        
        /// Monitor for clicks within our own app.
        clickOutsideLocalMonitor = NSEvent.addLocalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [self] event in
            let screenLocation = NSEvent.mouseLocation
            if !hintManager.isClickInsideWindows(screenLocation) {
                DispatchQueue.main.async {
                    self.hideMoreMenu()
                }
            }
            return event
        }
                                                                                                                                
        /// Monitor for clicks outside our app.
        clickOutsideGlobalMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [self] _ in
            DispatchQueue.main.async {
                self.hideMoreMenu()
            }
        }
    }

    func removeClickOutsideMonitor() {
        if let monitor = clickOutsideLocalMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideLocalMonitor = nil
        }
        
        if let monitor = clickOutsideGlobalMonitor {
            NSEvent.removeMonitor(monitor)
            clickOutsideGlobalMonitor = nil
        }
    }
    
    // MARK: - Functions: Visibility Toggles
    
    func toggleMoreMenu() {
        if shouldShowMoreMenu {
            hideMoreMenu()
        } else {
            showMoreMenu()
        }
    }

    private func showMoreMenu() {
        guard !isDragging else { return }

        shouldShowMoreMenu = true
        setupClickOutsideMonitor()
        hintManager.showMoreMenu(swiftUIView: moreMenuView)
    }

    func hideMoreMenu() {
        shouldShowMoreMenu = false
        removeClickOutsideMonitor()
        hintManager.hideMoreMenu()

        /// Re-evaluate popup after a brief delay.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let popUpMessageType = activePopUpMessageType {
                showPopUpMessage(type: popUpMessageType)
            }
        }
    }

    // MARK: - Private Functions

    private func openSettings() {
        hideMoreMenu()
        SettingsWindowManager.shared.showWindow(page: .general)
    }

    // MARK: - Child Components

    var moreMenuView: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 0) {
                moreMenuOpenSettingsButtonView
            }

//            moreMenuHideForOneHourButtonView
//            DividerHorizontal()
        }
        .padding(8)
        .background(Color.S_10.opacity(0.65))
        .background(Backgrounds.BrushedGlass())
        .addBorder(
            cornerRadius: 15,
            stroke: Color.T_8
        )
        .fixedSize()
        .addAnimation(dependency: shouldShowMoreMenu)
    }

    private var moreMenuHideForOneHourButtonView: some View {
        MoreMenuItemButtonView(
            text: String.localized("Hide for 1h", table: "MenuBar"),
            disabled: tetheredButtonHideAllAppsTimerDate != nil
        ) {
            toggleHideForegroundWindowIconsForOneHour()
        }
    }

    private var moreMenuOpenSettingsButtonView: some View {
        MoreMenuItemButtonView(
            text: String.localized("Settings", table: "MenuBar")
        ) {
            openSettings()
        }
    }
    
    private struct MoreMenuItemButtonView: View {
        let text: String
        var disabled: Bool = false
        var shortcut: String? = nil
        let action: () -> Void

        @State private var isHovered = false

        var body: some View {
            Button {
                action()
            } label: {
                HStack(alignment: .center, spacing: 8) {
                    Text(text)
                        .styleText(
                            size: 13,
                            weight: .regular,
                            color: disabled ? Color.T_3 : Color.S_0
                        )
                        .truncateText()

                    Spacer()

                    if let shortcut = shortcut {
                        Text(shortcut)
                            .styleText(
                                size: 13,
                                weight: .regular,
                                color: Color.T_2
                            )
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.horizontal, 10)
            .frame(height: 22, alignment: .center)
            .background(
                isHovered && !disabled ? Color.T_8 : Color.clear
            )
            .cornerRadius(6)
            .contentShape(Rectangle())
            .disabled(disabled)
            .onHover { isHovered in
                self.isHovered = isHovered
            }
            .addAnimation(dependency: isHovered)
        }
    }
}
