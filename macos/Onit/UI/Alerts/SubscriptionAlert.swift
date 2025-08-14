//
//  SubscriptionAlert.swift
//  Onit
//
//  Created by Loyd Kim on 5/2/25.
//

import SwiftUI

struct SubscriptionAlert: View {
    @Environment(\.appState) var appState
    @Environment(\.openSettings) var openSettings
    
    private let title: String
    private let close: (() -> Void)?
    private let description: String
    private let descriptionLoading: Bool
    private let descriptionAction: (() -> Void)?
    private let descriptionActionLoading: Bool
    private let caption: String?
    private let subscriptionText: String?
    private let subscriptionAction: (() -> Void)?
    private let showSubscriptionPerks: Bool
    private let footerSupportingText: String?
    private let errorMessage: Binding<String>?
    
    init(
        title: String,
        close: (() -> Void)? = nil,
        description: String,
        descriptionLoading: Bool = false,
        descriptionAction: (() -> Void)? = nil,
        descriptionActionLoading: Bool = false,
        caption: String? = nil,
        subscriptionText: String? = nil,
        subscriptionAction: (() -> Void)? = nil,
        showSubscriptionPerks: Bool = false,
        footerSupportingText: String? = nil,
        errorMessage: Binding<String>? = nil
    ) {
        self.title = title
        self.close = close
        self.description = description
        self.descriptionLoading = descriptionLoading
        self.descriptionAction = descriptionAction
        self.descriptionActionLoading = descriptionActionLoading
        self.caption = caption
        self.subscriptionText = subscriptionText
        self.subscriptionAction = subscriptionAction
        self.showSubscriptionPerks = showSubscriptionPerks
        self.footerSupportingText = footerSupportingText
        self.errorMessage = errorMessage
    }
    
    var body: some View {
        HStack(alignment: .center) {
            VStack(alignment: .center, spacing: 16) {
                if let errorMessage = errorMessage,
                    !errorMessage.wrappedValue.isEmpty
                {
                    Text(errorMessage.wrappedValue)
                        .styleText(
                            size: 13,
                            weight: .regular,
                            color: Color.red500
                        )
                }
                
                header
                
                VStack(alignment: .center, spacing: 8) {
                    if descriptionActionLoading {
                        Shimmer(width: 220, height: 16)
                    } else if let descriptionAction = descriptionAction {
                        descriptionButton(descriptionAction)
                            .opacity(descriptionActionLoading ? 0.5 : 1)
                            .allowsHitTesting(!descriptionActionLoading)
                    } else {
                        descriptionText
                    }
                    
                    if let caption = caption {
                        Text(caption).styleText(size: 13, weight: .regular)
                    }
                }
                
                if let subscriptionText = subscriptionText {
                    SubscriptionButton(text: subscriptionText, action: subscriptionAction)
                }
                
                if showSubscriptionPerks {
                    SubscriptionFeatures(centerErrorText: true)
                }
                
                footer
            }
            .padding(16)
            .background(Color.elevatedBG)
            .addBorder()
            .padding(22)
            .transition(.opacity)
        }
        .frame(maxHeight: .infinity)
        .background(
            GlassBackground()
                .onTapGesture {
                    close?()
                }
        )
    }
}

// MARK: - Child Components

extension SubscriptionAlert {
    private func closeButton(_ close: @escaping () -> Void) -> some View {
        Button {
            close()
        } label: {
            Image(.smallCross)
                .addIconStyles(foregroundColor: Color.S_1, iconSize: 18)
        }
        .buttonStyle(PlainButtonStyle())
        .offset(x: 6, y: -6)
    }
    
    private var header: some View {
        HStack(alignment: .top) {
            if let close = close { closeButton(close).opacity(0).allowsHitTesting(false) }
            Spacer()
            
            Text(title).styleText(size: 16, weight: .semibold)
            
            Spacer()
            if let close = close { closeButton(close) }
        }
    }
    
    private var descriptionText: some View {
        Text(description)
            .styleText(
                size: 13,
                weight: .regular,
                color: Color.S_1,
                align: .center
            )
    }
    
    private func descriptionButton(_ action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            Text(description)
                .styleText(
                    size: 13,
                    weight: .regular,
                    align: .center
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func footerTextView(_ text: String) -> some View {
        Text(text).styleText(size: 11, color: Color.S_2)
    }
    
    private var footer: some View {
        VStack(alignment: .center, spacing: 16) {
            DividerHorizontal()
            
            VStack(alignment: .center, spacing: 4) {
                if let footerSupportingText = footerSupportingText {
                    footerTextView(footerSupportingText)
                }
                
                HStack(spacing: 4) {
                    footerTextView("Or, add your API key in")
                    
                    Button {
                        openModelSettings()
                    } label: {
                        Text("Settings").styleText(size: 11, color: Color.S_1)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }
}

// MARK: -  Private Functions

extension SubscriptionAlert {
    private func openModelSettings() {
        NSApp.activate()
        
        if NSApp.isActive {
            appState.setSettingsTab(tab: .models)
            openSettings()
        }
    }
}
