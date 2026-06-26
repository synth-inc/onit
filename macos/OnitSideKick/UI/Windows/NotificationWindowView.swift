//
//  NotificationWindowView.swift
//  Onit
//
//  Created by Loyd Kim on 10/6/25.
//

import SwiftUI

struct NotificationWindowView: View {
    // MARK: - Types

    typealias Action = (
        textKey: String,
        shouldCloseWindow: Bool,
        callback: (() -> Void)?
    )

    // MARK: - Observed Objects

    @ObservedObject private var localization = LocalizationManager.shared

    // MARK: - Properties

    private let createdAt: Date
    private let titleKey: String
    private let captionKey: String?
    private let image: ImageResource?
    private let primaryAction: Action?
    private let secondaryAction: Action?
    private let closeButtonCallback: (() -> Void)?

    init(
        createdAt: Date,
        titleKey: String,
        captionKey: String? = nil,
        image: ImageResource? = nil,
        primaryAction: Action? = nil,
        secondaryAction: Action? = nil,
        closeButtonCallback: (() -> Void)? = nil
    ) {
        self.createdAt = createdAt
        self.titleKey = titleKey
        self.captionKey = captionKey
        self.image = image
        self.primaryAction = primaryAction
        self.secondaryAction = secondaryAction
        self.closeButtonCallback = closeButtonCallback
    }
    
    // MARK: - Private Variables
    
    private let notificationWindowManager = NotificationWindowManager.shared
    
    private var hasAction: Bool {
        return self.primaryAction != nil || self.secondaryAction != nil
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            self.header

            self.imageView

            VStack(alignment: .leading, spacing: 8) {
                self.titleView
                self.captionView
            }

            self.actionButtons
        }
        .padding([.horizontal, .bottom], 20)
        .padding(.top, 15)
        .frame(width: 306)
        .background(Color.baseBG.opacity(0.7))
        .background(Backgrounds.BrushedGlass())
        .cornerRadius(26)
        .id(localization.currentLanguage)
    }
    
    // MARK: - Child Components
    
    private var logo: some View {
        Image(.logo)
            .resizable()
            .frame(width: 19, height: 19)
    }
    
    private var closeButton: some View {
        IconButton(
            icon: .cross,
            iconSize: 9
        ) {
            self.closeWindow()
            self.closeButtonCallback?()
        }
    }
    
    private var header: some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 6) {
                self.logo

                Text("SideKick")
                    .styleText(
                        size: 13,
                        color: Color.S_1
                    )
            }
            
            Spacer()
            
            closeButton
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        if let image = self.image {
            Image(image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(16)
                .padding(.bottom, 6)
        }
    }
    
    private var titleView: some View {
        Text(String.localized(self.titleKey))
            .styleText(
                size: 14,
                weight: .medium
            )
    }

    @ViewBuilder
    private var captionView: some View {
        if let captionKey = self.captionKey {
            Text(String.localized(captionKey))
                .styleText(
                    size: 13,
                    weight: .regular,
                    color: Color.S_1
                )
        }
    }
    
    @ViewBuilder
    private var primaryActionButton: some View {
        if let primaryAction = self.primaryAction {
            SimpleButton(
                text: String.localized(primaryAction.textKey),
                textColor: Color.S_10,
                textWeight: .medium,
                cornerRadius: 6,
                action: {
                    primaryAction.callback?()

                    if primaryAction.shouldCloseWindow {
                        self.closeWindow()
                    }
                },
                background: Color.S_0
            )
        }
    }

    @ViewBuilder
    private var secondaryActionButton: some View {
        if let secondaryAction = self.secondaryAction {
            SimpleButton(
                text: String.localized(secondaryAction.textKey),
                textWeight: .medium,
                action: {
                    secondaryAction.callback?()

                    if secondaryAction.shouldCloseWindow {
                        self.closeWindow()
                    }
                },
                background: Color.clear,
                hoverBackground: Color.T_8
            )
        }
    }
    
    @ViewBuilder
    private var actionButtons: some View {
        if self.hasAction {
            HStack(alignment: .center, spacing: 8) {
                self.primaryActionButton
                self.secondaryActionButton
            }
            .padding(.top, 3)
        }
    }
    
    // MARK: - Private Functions
    
    private func closeWindow() {
        notificationWindowManager.closeWindow(createdAt: self.createdAt)
    }
}
